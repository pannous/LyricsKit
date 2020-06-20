//
//  Gecimi.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

import Foundation
import LyricsCore
import CXShim
import CXExtensions

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let gecimiLyricsBaseURL = URL(string: "http://gecimi.com/api/lyric")!
private let gecimiCoverBaseURL = URL(string:"http://gecimi.com/api/cover")!

extension LyricsProviders {
    public final class Gecimi {
        public init() {}
    }
}

extension LyricsProviders.Gecimi: _LyricsProvider {
    
    public static let service: LyricsProviders.Service = .gecimi
    
    func lyricsSearchPublisher(request: LyricsSearchRequest) -> AnyPublisher<GecimiResponseSearchResult.Result, Never> {
        guard case let .info(title, artist) = request.searchTerm else {
            // cannot search by keyword
            return Empty().eraseToAnyPublisher()
        }
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .uriComponentAllowed)!
        let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .uriComponentAllowed)!
        
        let url = gecimiLyricsBaseURL.appendingPathComponent("\(encodedTitle)/\(encodedArtist)")
        let req = URLRequest(url: url)
        
        return sharedURLSession.cx.dataTaskPublisher(for: req)
            .map { $0.data }
            .decode(type: GecimiResponseSearchResult.self, decoder: JSONDecoder().cx)
            .map(\.result)
            .replaceError(with: [])
            .flatMap(Publishers.Sequence.init)
            .eraseToAnyPublisher()
    }
    
    func lyricsFetchPublisher(token: GecimiResponseSearchResult.Result) -> AnyPublisher<Lyrics, Never> {
        return sharedURLSession.cx.dataTaskPublisher(for: token.lrc)
            .compactMap {
                guard let lrcContent = String(data: $0.data, encoding: .utf8),
                    let lrc = Lyrics(lrcContent) else {
                        return nil
                }
                lrc.metadata.remoteURL = token.lrc
                lrc.metadata.service = Self.service
                lrc.metadata.serviceToken = "\(token.aid),\(token.lrc)"
                return lrc
            }.ignoreError()
            .eraseToAnyPublisher()
    }
}
