//
//  LyricsQQ.swift
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

private let qqSearchBaseURLString = "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
private let qqLyricsBaseURLString = "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg"

extension LyricsProviders {
    public final class QQMusic {
            public init() {}
    }
}

extension LyricsProviders.QQMusic: _LyricsProvider {
    
    public static let service: LyricsProviders.Service = .qq
    
    func lyricsSearchPublisher(request: LyricsSearchRequest) -> AnyPublisher<QQResponseSearchResult.Data.Song.Item, Never> {
        let parameter = ["w": request.searchTerm.description]
        let url = URL(string: qqSearchBaseURLString + "?" + parameter.stringFromHttpParameters)!
        
        return sharedURLSession.cx.dataTaskPublisher(for: url)
            .map { $0.data.dropFirst(9).dropLast() }
            .decode(type: QQResponseSearchResult.self, decoder: JSONDecoder().cx)
            .map(\.data.song.list)
            .replaceError(with: [])
            .flatMap(Publishers.Sequence.init)
            .eraseToAnyPublisher()
    }
    
    func lyricsFetchPublisher(token: QQResponseSearchResult.Data.Song.Item) -> AnyPublisher<Lyrics, Never> {
        let parameter: [String: Any] = [
            "songmid": token.songmid,
            "g_tk": 5381
        ]
        let url = URL(string: qqLyricsBaseURLString + "?" + parameter.stringFromHttpParameters)!
        var req = URLRequest(url: url)
        req.setValue("y.qq.com/portal/player.html", forHTTPHeaderField: "Referer")
        return sharedURLSession.cx.dataTaskPublisher(for: req)
            .compactMap {
                let data = $0.data.dropFirst(18).dropLast()
                guard let model = try? JSONDecoder().decode(QQResponseSingleLyrics.self, from: data),
                    let lrcContent = model.lyricString,
                    let lrc = Lyrics(lrcContent) else {
                        return nil
                }
                if let transLrcContent = model.transString,
                    let transLrc = Lyrics(transLrcContent) {
                    lrc.merge(translation: transLrc)
                }
                
                lrc.idTags[.title] = token.songname
                lrc.idTags[.artist] = token.singer.first?.name
                lrc.idTags[.album] = token.albumname
                
                lrc.length = Double(token.interval)
                lrc.metadata.service = Self.service
                lrc.metadata.serviceToken = "\(token.songmid)"
                if let id = Int(token.songmid) {
                    lrc.metadata.artworkURL = URL(string: "http://imgcache.qq.com/music/photo/album/\(id % 100)/\(id).jpg")
                }
                return lrc
            }.ignoreError()
            .eraseToAnyPublisher()
    }
}
