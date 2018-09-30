//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation

/// The `help` command.
func helpMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    guard let commandDictionaryURL = Bundle.main.url(forResource: "commandDictionary", withExtension: "plist"), let extraCommandDictionaryURL = Bundle.main.url(forResource: "extraCommandsDictionary", withExtension: "plist") else {
        return 1
    }
    
    guard let commandDictionary = NSDictionary(contentsOf: commandDictionaryURL) as? [String:Any], let extraCommandDictionary = NSDictionary(contentsOf: extraCommandDictionaryURL) as? [String: Any] else {
        return 1
    }
    
    var commands = [String]()
    
    for (name, _) in commandDictionary {
        commands.append(name)
    }
    
    for (name, _) in extraCommandDictionary {
        commands.append(name)
    }
    
    for (name, _) in shell.builtins {
        commands.append(name)
    }
    
    guard let data = commands.joined(separator: ", ").data(using: .utf8) else {
        return 1
    }
    
    shell.io.outputPipe.fileHandleForWriting.write(data)
    
    return 0
}
