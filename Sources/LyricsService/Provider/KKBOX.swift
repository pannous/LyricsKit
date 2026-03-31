//
//  KKBOX.swift
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

private let kkboxSearchBaseURLString = "https://www.kkbox.com/tw/tc/search.php"

extension LyricsProviders {
    public final class KKBOX {
        public init() {}
    }
}

extension LyricsProviders.KKBOX: _LyricsProvider {

    public struct LyricsToken {
        let songID: String
        let title: String
        let artist: String
        let album: String
    }

    public static let service: LyricsProviders.Service? = .kkbox

    public func lyricsSearchPublisher(request: LyricsSearchRequest) -> AnyPublisher<LyricsToken, Never> {
        let searchTerm = request.searchTerm.description
        let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm
        let urlString = "\(kkboxSearchBaseURLString)?word=\(encodedTerm)&type=lyrics"

        guard let url = URL(string: urlString) else {
            return Empty().eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        return sharedURLSession.dataTaskPublisher(for: req)
            .map { $0.data }
            .compactMap { data -> [LyricsToken]? in
                guard let html = String(data: data, encoding: .utf8) else { return nil }
                return self.parseSearchResults(html)
            }
            .replaceError(with: [])
            .flatMap(Publishers.Sequence.init)
            .eraseToAnyPublisher()
    }

    private func parseSearchResults(_ html: String) -> [LyricsToken] {
        var results: [LyricsToken] = []

        // Parse HTML to extract song information
        // KKBOX search results contain song IDs in URLs like: /song/songID
        let songIDPattern = #"\/song\/([A-Za-z0-9_-]+)"#
        let titlePattern = #"<h2[^>]*>([^<]+)<\/h2>"#

        if let songIDRegex = try? NSRegularExpression(pattern: songIDPattern),
           let titleRegex = try? NSRegularExpression(pattern: titlePattern) {

            let nsString = html as NSString
            let range = NSRange(location: 0, length: nsString.length)

            let songIDMatches = songIDRegex.matches(in: html, range: range)
            let titleMatches = titleRegex.matches(in: html, range: range)

            for (index, match) in songIDMatches.enumerated() {
                if match.numberOfRanges > 1 {
                    let songID = nsString.substring(with: match.range(at: 1))
                    var title = "Unknown"
                    let artist = "Unknown"

                    if index < titleMatches.count && titleMatches[index].numberOfRanges > 1 {
                        title = nsString.substring(with: titleMatches[index].range(at: 1))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    let token = LyricsToken(
                        songID: songID,
                        title: title,
                        artist: artist,
                        album: ""
                    )
                    results.append(token)
                }
            }
        }

        return results
    }

    public func lyricsFetchPublisher(token: LyricsToken) -> AnyPublisher<Lyrics, Never> {
        let urlString = "https://www.kkbox.com/tw/tc/song/\(token.songID)"
        guard let url = URL(string: urlString) else {
            return Just(Lyrics(lines: [], idTags: [:])).eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        return sharedURLSession.dataTaskPublisher(for: req)
            .compactMap { response -> Lyrics? in
                guard let html = String(data: response.data, encoding: .utf8) else { return nil }
                return self.parseLyrics(html, token: token)
            }
            .replaceError(with: Lyrics(lines: [], idTags: [:]))
            .eraseToAnyPublisher()
    }

    private func parseLyrics(_ html: String, token: LyricsToken) -> Lyrics? {
        // Parse lyrics from KKBOX HTML page
        // Look for lyrics content in div or pre tags
        let lyricsPattern = #"<div[^>]*class="[^"]*lyrics[^"]*"[^>]*>([\s\S]*?)<\/div>"#

        guard let regex = try? NSRegularExpression(pattern: lyricsPattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)

        if let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1 {
            var lyricsHTML = nsString.substring(with: match.range(at: 1))

            // Clean HTML tags
            lyricsHTML = lyricsHTML.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
            lyricsHTML = lyricsHTML.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            lyricsHTML = lyricsHTML.replacingOccurrences(of: "&nbsp;", with: " ")
            lyricsHTML = lyricsHTML.replacingOccurrences(of: "&quot;", with: "\"")
            lyricsHTML = lyricsHTML.replacingOccurrences(of: "&amp;", with: "&")
            lyricsHTML = lyricsHTML.trimmingCharacters(in: .whitespacesAndNewlines)

            // Filter out "no lyrics available" messages in various languages
            let noLyricsMessages = [
                "這首歌曲暫無歌詞",  // Chinese Traditional: This song has no lyrics
                "这首歌曲暂无歌词",  // Chinese Simplified
                "此歌曲暫無歌詞",    // Alternative Traditional
                "No lyrics available",
                "Lyrics not available",
                "純音樂，無歌詞",    // Pure music, no lyrics
                "纯音乐，无歌词"     // Simplified version
            ]

            for message in noLyricsMessages {
                if lyricsHTML.contains(message) {
                    print("⚠️ KKBOX: No lyrics available - \(message)")
                    return nil
                }
            }

            let lyrics = Lyrics(lines: [], idTags: [:])
            lyrics.idTags[.title] = token.title
            lyrics.idTags[.artist] = token.artist
            lyrics.idTags[.album] = token.album

            // Split into lines and create LyricsLine objects
            let lines = lyricsHTML.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let lyricsLine = LyricsLine(content: trimmed, position: TimeInterval(index))
                    lyrics.lines.append(lyricsLine)
                }
            }

            return lyrics.lines.isEmpty ? nil : lyrics
        }

        return nil
    }
}
