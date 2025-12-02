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
        let searchTerm = request.searchTerm.description
        let components = searchTerm.components(separatedBy: " - ")

        var queryParams: [String: String] = [:]

        if components.count >= 2 {
            queryParams["artist_name"] = components[0].trimmingCharacters(in: .whitespaces)
            queryParams["track_name"] = components[1].trimmingCharacters(in: .whitespaces)
        } else {
            queryParams["q"] = searchTerm
        }

        let queryString = queryParams.map { key, value in
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
