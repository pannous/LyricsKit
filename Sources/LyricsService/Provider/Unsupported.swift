//
//  ViewLyrics.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2020  Xander Deng. Licensed under GPLv3.
//

import Foundation
import LyricsCore
import CXShim

extension LyricsProviders {
    public final class Unsupported {
        public init() {}
    }
}

extension LyricsProviders.Unsupported: LyricsProvider {
    
    public func lyricsPublisher(request: LyricsSearchRequest) -> AnyPublisher<Lyrics, Never> {
        return Empty<Lyrics, Never>().eraseToAnyPublisher()
    }
}
