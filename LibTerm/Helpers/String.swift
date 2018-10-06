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
        var components = self.components(separatedBy: .whitespaces)
        
        // Separate in to command and arguments
        
        let program = components[0]
        let args = Array(components[1..<components.endIndex])
        
        var parsedArgs = [String]()
        
        var currentArg = ""
        
        for arg in args {
            
            if arg.hasPrefix("\"") {
                
                if currentArg.isEmpty {
                    
                    currentArg = arg
                    currentArg.removeFirst()
                    
                } else {
                    
                    currentArg.append(" " + arg)
                    
                }
                
            } else if arg.hasSuffix("\"") {
                
                if currentArg.isEmpty {
                    
                    currentArg.append(arg)
                    
                } else {
                    
                    currentArg.append(" " + arg)
                    currentArg.removeLast()
                    parsedArgs.append(currentArg)
                    currentArg = ""
                    
                }
                
            } else {
                
                if currentArg.isEmpty {
                    parsedArgs.append(arg)
                } else {
                    currentArg.append(" " + arg)
                }
                
            }
            
        }
        
        if !currentArg.isEmpty {
            parsedArgs.append(currentArg)
        }
        
        parsedArgs.insert(self.components(separatedBy: .whitespaces)[0], at: 0)
        
        func removeEmpty() {
            var i = 0
            for arg in parsedArgs {
                if arg.isEmpty {
                    parsedArgs.remove(at: i)
                    removeEmpty()
                    break
                }
                i += 1
            }
        }
        removeEmpty()
        return parsedArgs
    }
}
