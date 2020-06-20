//
//  LyricsProviderManager.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

import Foundation
import LyricsCore
import CXShim

extension LyricsProviders {
    
    public final class Group: LyricsProvider {
        
        var providers: [LyricsProvider]
        
        public init(sources: [LyricsProviders.Service] = LyricsProviders.Service.allCases) {
            providers = sources.map { $0.create() }
        }
        
        public func lyricsPublisher(request: LyricsSearchRequest) -> AnyPublisher<Lyrics, Never> {
            return providers.cx.publisher
                .flatMap { $0.lyricsPublisher(request: request) }
                .eraseToAnyPublisher()
        }
    }
}
