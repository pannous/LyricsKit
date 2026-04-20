//
//  LRCLib.swift
//  LyricsX
//
//  Created for Lyrics Translator
//

import Foundation
import LyricsCore
import Combine
import CXExtensions

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let lrclibSearchBaseURL = "https://lrclib.net/api/search"
private let lrclibGetBaseURL = "https://lrclib.net/api/get"

extension LyricsProviders {
    public final class LRCLib {
        public init() {}
    }
}

extension LyricsProviders.LRCLib: _LyricsProvider {

    public struct LyricsToken {
        let id: Int
        let trackName: String
        let artistName: String
        let albumName: String?
        let duration: Double?
    }

    public static let service: LyricsProviders.Service? = .lrclib

    public func lyricsSearchPublisher(request: LyricsSearchRequest) -> AnyPublisher<LyricsToken, Never> {
        // Build two search strategies:
        //   1. structured (track_name + artist_name) — precise but fails when
        //      LRCLib stores the artist under a romanised variant
        //   2. generic q= keyword — broader, catches romanised names
        // Build up to three search strategies (most → least specific):
        //   1. structured: track_name + artist_name
        //   2. q= with "title artist" combined
        //   3. q= with title only (catches fully romanised artist names)
        var searches: [[String: String]] = []

        switch request.searchTerm {
        case let .info(title, artist) where !artist.isEmpty:
            searches.append(["track_name": title, "artist_name": artist])
            searches.append(["q": "\(title) \(artist)"])
            searches.append(["q": title])
        default:
            searches.append(["q": request.searchTerm.description])
        }

        return _lrclibSearchWithFallbacks(searches: searches, index: 0)
    }

    /// Tries each search strategy in order, returning the first non-empty result.
    private func _lrclibSearchWithFallbacks(searches: [[String: String]], index: Int) -> AnyPublisher<LyricsToken, Never> {
        guard index < searches.count else {
            return Empty().eraseToAnyPublisher()
        }
        return _lrclibSearch(params: searches[index])
            .collect()
            .flatMap { results -> AnyPublisher<LyricsToken, Never> in
                if !results.isEmpty {
                    return Publishers.Sequence(sequence: results).eraseToAnyPublisher()
                }
                print("🔄 LRCLib: search \(index + 1)/\(searches.count) returned empty, trying next")
                return self._lrclibSearchWithFallbacks(searches: searches, index: index + 1)
            }
            .eraseToAnyPublisher()
    }

    /// Low-level LRCLib search request for a single set of query parameters.
    private func _lrclibSearch(params: [String: String]) -> AnyPublisher<LyricsToken, Never> {
        let queryString = params.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }.joined(separator: "&")

        guard let url = URL(string: "\(lrclibSearchBaseURL)?\(queryString)") else {
            return Empty().eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.setValue("Lyrics-Translator/1.0", forHTTPHeaderField: "User-Agent")

        print("🔍 LRCLib search URL: \(url.absoluteString)")

        return sharedURLSession.dataTaskPublisher(for: req)
            .map { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 LRCLib search response: \(httpResponse.statusCode)")
                }
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📦 LRCLib search data: \(jsonString.prefix(500))")
                }
                return data
            }
            .decode(type: [LRCLibSearchResult].self, decoder: JSONDecoder())
            .catch { error -> Just<[LRCLibSearchResult]> in
                print("❌ LRCLib decode error: \(error)")
                return Just([])
            }
            .flatMap(Publishers.Sequence.init)
            .map { result in
                print("✅ LRCLib found: \(result.artistName) - \(result.trackName)")
                return LyricsToken(
                    id: result.id,
                    trackName: result.trackName,
                    artistName: result.artistName,
                    albumName: result.albumName,
                    duration: result.duration
                )
            }
            .eraseToAnyPublisher()
    }

    public func lyricsFetchPublisher(token: LyricsToken) -> AnyPublisher<Lyrics, Never> {
        var components = URLComponents(string: lrclibGetBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "track_name", value: token.trackName),
            URLQueryItem(name: "artist_name", value: token.artistName)
        ]

        if let albumName = token.albumName {
            components.queryItems?.append(URLQueryItem(name: "album_name", value: albumName))
        }

        if let duration = token.duration {
            components.queryItems?.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }

        guard let url = components.url else {
            return Just(Lyrics(lines: [], idTags: [:])).eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.setValue("Lyrics-Translator/1.0", forHTTPHeaderField: "User-Agent")

        return sharedURLSession.dataTaskPublisher(for: req)
            .compactMap { response -> Lyrics? in
                guard let result = try? JSONDecoder().decode(LRCLibLyricsResult.self, from: response.data) else {
                    return nil
                }
                return self.parseLyrics(result)
            }
            .replaceError(with: Lyrics(lines: [], idTags: [:]))
            .eraseToAnyPublisher()
    }

    private func parseLyrics(_ result: LRCLibLyricsResult) -> Lyrics? {
        // Prefer synced lyrics if available
        let lrcContent = result.syncedLyrics ?? result.plainLyrics

        guard let lrcContent = lrcContent, !lrcContent.isEmpty else {
            print("⚠️ LRCLib: No lyrics available")
            return nil
        }

        guard let lyrics = Lyrics(lrcContent) else {
            print("⚠️ LRCLib: Failed to parse lyrics")
            return nil
        }

        lyrics.idTags[.title] = result.trackName
        lyrics.idTags[.artist] = result.artistName
        lyrics.idTags[.album] = result.albumName

        if let duration = result.duration {
            lyrics.length = Double(duration)
        }

        lyrics.metadata.serviceToken = "\(result.id)"

        print("✅ LRCLib: Got lyrics (synced: \(result.syncedLyrics != nil))")
        return lyrics
    }
}

// MARK: - Response Models

private struct LRCLibSearchResult: Codable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
}

private struct LRCLibLyricsResult: Codable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: Double?
    let plainLyrics: String?
    let syncedLyrics: String?
}
