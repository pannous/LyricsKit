//
//  LyricsLineAttachment.swift
//
//  This file is part of LyricsX - https://github.com/pannous/LyricsX
//  Copyright (C) 2017  Xander Deng. Licensed under GPLv3.
//

import Foundation

public protocol LyricsLineAttachment: LosslessStringConvertible {}

// MARK: - LyricsLine.Attachments

extension LyricsLine {
    
    public struct Attachments {
        
        var content: [Tag: LyricsLineAttachment]
        
        public init(attachments: [Tag: LyricsLineAttachment] = [:]) {
            self.content = attachments
        }
        
        public struct Tag: RawRepresentable, Equatable, Hashable {
            
            public var rawValue: String
            
            public init(rawValue: String) {
                self.init(rawValue)
            }
        }
    }
}

extension LyricsLine.Attachments {
    
    public var timetag: LyricsLine.Attachments.WordTimeTag? {
        get {
            return content[.timetag] as? LyricsLine.Attachments.WordTimeTag
        }
        set {
            content[.timetag] = newValue
        }
    }
    
    public func translation(languageCode: String? = nil) -> String? {
        let tag = languageCode.map(LyricsLine.Attachments.Tag.translation) ?? LyricsLine.Attachments.Tag.translation
        return (content[tag] as? LyricsLine.Attachments.PlainText)?.text
    }
    
    public mutating func setTranslation(_ str: String, languageCode: String? = nil) {
        let tag = languageCode.map(LyricsLine.Attachments.Tag.translation) ?? LyricsLine.Attachments.Tag.translation
        return content[tag] = LyricsLine.Attachments.createAttachment(str: str, tag: tag)
    }
    
    public subscript(_ tag: String) -> String? {
        get {
            return content[.init(tag)]?.description
        }
        set {
            let t = LyricsLine.Attachments.Tag(tag)
            content[t] = newValue.flatMap { LyricsLine.Attachments.createAttachment(str: $0, tag: t) }
        }
    }
    
    static func createAttachment(str: String, tag: LyricsLine.Attachments.Tag) -> LyricsLineAttachment? {
        switch tag {
        case .timetag:
            return LyricsLine.Attachments.WordTimeTag(str)
        case .furigana, .romaji:
            return LyricsLine.Attachments.RangeAttribute(str)
        default:
            return LyricsLine.Attachments.PlainText(str)
        }
    }
}

extension LyricsLine.Attachments: Equatable {
    
    public static func == (lhs: LyricsLine.Attachments, rhs: LyricsLine.Attachments) -> Bool {
        guard lhs.content.count == rhs.content.count else {
            return false
        }
        for (lkey, lvalue) in lhs.content {
            guard let rvalue = rhs.content[lkey],
                rvalue.description == lvalue.description else {
                return false
            }
        }
        return true
    }
}

// MARK: - LyricsLine.Attachments.Tag

extension LyricsLine.Attachments.Tag {
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let translation: LyricsLine.Attachments.Tag = "tr"
    public static let timetag: LyricsLine.Attachments.Tag = "tt"
    public static let furigana: LyricsLine.Attachments.Tag = "fu"
    public static let romaji: LyricsLine.Attachments.Tag = "ro"
    
    public static func translation(languageCode: String) -> LyricsLine.Attachments.Tag {
        if languageCode.isEmpty {
            return .init("tr")
        } else {
            return .init("tr:" + languageCode)
        }
    }
    
    public var isTranslation: Bool {
        return rawValue.hasPrefix("tr")
    }
}

extension LyricsLine.Attachments.Tag: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
}

extension LyricsLine.Attachments.Tag: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - LyricsLine.Attachments.PlainText

extension LyricsLine.Attachments {
    
    public struct PlainText: LyricsLineAttachment {
    
        public var text: String
        
        public var description: String {
            return text
        }
        
        public init(_ description: String) {
            text = description
        }
    }
}

// MARK: - LyricsLine.Attachments.WordTimeTag

extension LyricsLine.Attachments {

    public struct WordTimeTag: LyricsLineAttachment {
        
        public struct Tag {
            public var index: Int
            public var timeTag: TimeInterval  // since the line begin
            
            public var timeTagMSec: Int {
                get { return Int(timeTag * 1000) }
                set { timeTag = TimeInterval(newValue) / 1000 }
            }
            
            public init(timeTag: TimeInterval, index: Int) {
                self.timeTag = timeTag
                self.index = index
            }
        }
        
        public var tags: [Tag]
        public var duration: TimeInterval?
        
        public var durationMSec: Int? {
            get { return duration.map { Int($0 * 1000) } }
            set { duration = newValue.map { TimeInterval($0) / 1000 } }
        }
        
        public var description: String {
            var result = tags.map { $0.description }.joined()
            if let durationMSec = durationMSec {
                result += "<\(durationMSec)>"
            }
            return result
        }
        
        public init(tags: [Tag] = [], duration: TimeInterval? = nil) {
            self.tags = tags
            self.duration = duration
        }
        
        public init?(_ description: String) {
            let matchs = timeLineAttachmentRegex.matches(in: description)
            tags = matchs.compactMap { Tag($0[1]!.string) }
            guard !tags.isEmpty else {
                return nil
            }
            if let match = timeLineAttachmentDurationRegex.firstMatch(in: description) {
                durationMSec = Int(match[1]!.string)
            }
        }
    }
}

extension LyricsLine.Attachments.WordTimeTag.Tag: LosslessStringConvertible {
    
    public var description: String {
        return "<\(timeTagMSec),\(index)>"
    }
    
    public init?(_ description: String) {
        let components = description.components(separatedBy: ",")
        guard components.count == 2,
            let msec = Int(components[0]),
            let index = Int(components[1]) else {
                return nil
        }
        self.timeTag = TimeInterval(msec) / 1000
        self.index = index
    }
}

// MARK: - LyricsLine.Attachments.RangeAttribute

extension LyricsLine.Attachments {

    public struct RangeAttribute: LyricsLineAttachment {
        
        public struct Tag {
            
            public var content: String
            public var range: Range<Int>
            
            public init(content: String, range: Range<Int>) {
                self.content = content
                self.range = range
            }
        }
        
        public var attachment: [Tag]
        
        public var description: String {
            return attachment.map { $0.description }.joined()
        }
        
        public init?(_ description: String) {
            let matchs = rangeAttachmentRegex.matches(in: description)
            attachment = matchs.compactMap { Tag($0[1]!.string) }
            guard !attachment.isEmpty else {
                return nil
            }
        }
    }
}

extension LyricsLine.Attachments.RangeAttribute.Tag: LosslessStringConvertible {
    
    public var description: String {
        return "<\(content),\(range.lowerBound),\(range.upperBound)>"
    }
    
    public init?(_ description: String) {
        let components = description.components(separatedBy: ",")
        guard components.count == 3,
            let lb = Int(components[1]),
            let ub = Int(components[2]),
            lb < ub else {
                return nil
        }
        self.content = components[0]
        self.range = lb..<ub
    }
}
