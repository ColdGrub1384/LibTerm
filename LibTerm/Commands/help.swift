//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system

/// All available commands.
var Commands: [String] {
    var commands = [String]()
    for command in (commandsAsArray() as? [String]) ?? [] {
        if !command.hasSuffix("tex") && command != "textluac" {
            commands.append(command)
        }
    }
    commands.append("clear")
    commands.append("help")
    return commands
}

/// The `help` command.
func helpMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var helpText = ""
    for commandName in Commands {
        if commandName != Commands.last {
            helpText += "\(commandName), "
        } else {
            helpText += "\(commandName)\n"
        }
    }
    guard let data = helpText.data(using: .utf8) else {
        return 1
    }
    
    shell.io?.outputPipe.fileHandleForWriting.write(data)
    
    return 0
}
