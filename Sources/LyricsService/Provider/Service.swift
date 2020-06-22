//
//  LyricsProviderSource.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

import Foundation

extension LyricsProviders {
    
    public enum Service: String, CaseIterable {
        case netease = "163"
        case qq = "QQMusic"
        case xiami = "Xiami"
        case gecimi = "Gecimi"
        case disabled = "disabled!"
//        case viewLyrics = "ViewLyrics"
        //        case kugou = "Kugou"
//        case syair = "Syair"
    }
}

extension LyricsProviders.Service {
    
    func create() -> LyricsProvider {
        switch self {
        case .netease:  return LyricsProviders.NetEase()
        case .qq:       return LyricsProviders.QQMusic()
//        case .kugou:    return LyricsProviders.Kugou()
        case .xiami:    return LyricsProviders.Xiami()
        case .gecimi:   return LyricsProviders.Gecimi()
//        case .viewLyrics: return LyricsProviders.ViewLyrics()
        default:        return LyricsProviders.Unsupported()
        }
    }
}
