//
//  GecimiResponseCover.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

import Foundation

struct GecimiResponseCover: Decodable {
    let result: Result
    
    /*
    let count: Int
    let code: Int
     */
    
    struct Result: Decodable {
        let cover: URL
        let thumb: URL
    }
}
