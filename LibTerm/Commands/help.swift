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
    
    let commands = commandDictionary.keys
    let extraCommands = extraCommandDictionary.keys
    let builtinCommands = shell.builtins.keys
    
    var helpText = commands.joined(separator: ", ")+"\n\n"+extraCommands.joined(separator: ", ")+"\n\n"+builtinCommands.joined(separator: ", ")
    helpText += "\n"
    
    guard let data = helpText.data(using: .utf8) else {
        return 1
    }
    
    shell.io?.outputPipe.fileHandleForWriting.write(data)
    
    return 0
}
