//
//  File.swift
//  
//
//  Created by me on 20.06.20.
//

import Foundation
extension String {
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
    
    static func ~= (lhs: Substring, rhs: String) -> Bool {
          guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
          let range = NSRange(location: 0, length: lhs.utf16.count)
          return regex.firstMatch(in: String(lhs), options: [], range: range) != nil
      }
    static func ~= (lhs: String, rhs: Substring) -> Bool {
          guard let regex = try? NSRegularExpression(pattern: String(rhs)) else { return false }
          let range = NSRange(location: 0, length: lhs.utf16.count)
          return regex.firstMatch(in: lhs, options: [], range: range) != nil
      }
}
