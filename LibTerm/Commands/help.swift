//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system

/// The `help` command.
func helpMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var helpText = ""
    for command in commandsAsArray() {
        if let commandName = command as? String {
            helpText += "\(commandName), "
        }
    }
    helpText += "clear, help\n"
    
    guard let data = helpText.data(using: .utf8) else {
        return 1
    }
    
    shell.io?.outputPipe.fileHandleForWriting.write(data)
    
    return 0
}
