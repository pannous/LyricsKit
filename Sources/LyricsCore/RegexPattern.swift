//
//  RegexPattern.swift
//  LyricsX - https://github.com/ddddxxx/LyricsX
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
@_implementationOnly import Regex

private let timeTagRegex = try! Regex(#"\[([-+]?\d+):(\d+(?:\.\d+)?)\]"#)
func resolveTimeTag(_ str: String) -> [TimeInterval] {
    let matchs = timeTagRegex.matches(in: str)
    return matchs.map { match in
        let min = Double(match[1]!.content)!
        let sec = Double(match[2]!.content)!
        return min * 60 + sec
    }
}

let id3TagRegex = try! Regex(#"^(?!\[[+-]?\d+:\d+(?:\.\d+)?\])\[(.+?):(.+)\]$"#, options: .anchorsMatchLines)

let lyricsLineRegex = try! Regex(#"^((?:\[[+-]?\d+:\d+(?:\.\d+)?\])+)(?!\[)([^【\n\r]*)(?:【(.*)】)?"#, options: .anchorsMatchLines)

let base60TimeRegex = try! Regex(#"^\s*(?:(\d+):)?(\d+(?:.\d+)?)\s*$"#)

let lyricsLineAttachmentRegex = try! Regex(#"^(\[[+-]?\d+:\d+(?:\.\d+)?\])+\[(.+?)\](.*)"#, options: .anchorsMatchLines)

let timeLineAttachmentRegex = try! Regex(#"<(\d+,\d+)>"#)

let timeLineAttachmentDurationRegex = try! Regex(#"<(\d+)>"#)

let rangeAttachmentRegex = try! Regex(#"<([^,]+,\d+,\d+)>"#)
