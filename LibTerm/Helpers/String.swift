//
//  String.swift
//  Pyto
//
//  Created by Adrian Labbe on 9/9/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import Foundation

@objc extension NSString {
    
    /// Replaces the first occurrence of the given `String` with another `String`.
    ///
    /// - Parameters:
    ///     - string: String to replace.
    ///     - replacement: Replacement of `string`.
    ///
    /// - Returns: This string replacing the first occurrence of `string` with `replacement`.
    @objc func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        return (self as String).replacingFirstOccurrence(of: string, with: replacement)
    }
}


extension String {
    
    /// Replaces the first occurrence of the given `String` with another `String`.
    ///
    /// - Parameters:
    ///     - string: String to replace.
    ///     - replacement: Replacement of `string`.
    ///
    /// - Returns: This string replacing the first occurrence of `string` with `replacement`.
    func replacingFirstOccurrence(of string: String, with replacement: String) -> String {
        guard let range = self.range(of: string) else { return self }
        return replacingCharacters(in: range, with: replacement)
    }
    
    /// Returns a C pointer to pass this `String` to C functions.
    var cValue: UnsafeMutablePointer<Int8> {
        guard let cString = cString(using: .utf8) else {
            let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
            buffer.pointee = 0
            return buffer
        }
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: cString.count)
        memcpy(buffer, cString, cString.count)
        
        return buffer
    }
    
    /// Returns arguments from command.
    var arguments: [String] {
        return self.components(separatedBy: .whitespaces)
    }
    
    // MARK: - Equality
    
    static func ==(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedSame
    }
    
    static func <(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedAscending
    }
    
    static func <=(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedAscending || lhs.compare(rhs, options: .numeric) == .orderedSame
    }
    
    static func >(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedDescending
    }
    
    static func >=(lhs: String, rhs: String) -> Bool {
        return lhs.compare(rhs, options: .numeric) == .orderedDescending || lhs.compare(rhs, options: .numeric) == .orderedSame
    }
}
