//
//  Python3Unlocker.swift
//  LibTerm
//
//  Created by Adrian Labbe on 12/18/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system
import ObjectUserDefaults

/// This class is used for determining if Python 3 should be locked or not.
@objc public class Python3Locker: NSObject {
    
    /// The object determining if Python is purchased.
    @objc public static let isPython3Purchased = ObjectUserDefaults.standard.item(forKey: "python3")
    
    /// The version in wich the app was purchased. If is lower than 4.0, then Python 3.7 should be purchased to be used.
    @objc public static let originalApplicationVersion = ObjectUserDefaults.standard.item(forKey: "originalVersion")
    
    /// Returns `true` if Python 3.7 can be fully used.
    static var isUnlocked: Bool {
        if originalApplicationVersion.stringValue == nil {
            return isPython3Purchased.boolValue
        } else if originalApplicationVersion.stringValue! < "4.0" {
            return true
        } else {
            return isPython3Purchased.boolValue
        }
    }
    
    /// Checks if Python 3 should be accessible wtih given arguments.
    ///
    /// - Parameters:
    ///     - arguments: The arguments for running Python. For example, if Python 3 In App Purchase isn't bought, Python can be executed for running commands installed with `packages`.
    ///
    /// - Returns: `true` if Python should not be ran.
    @objc public static func isLocked(withArguments arguments: [String]) -> Bool {
                
        if arguments.count == 1 { // Cannot run REPL.
            return !isUnlocked
        }
        
        if !FileManager.default.fileExists(atPath: arguments[1]) {
            return !isUnlocked
        }
        
        if arguments[1].hasPrefix(FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].path) {
            return true
        }
        
        return !isUnlocked
    }
}
