//
//  Commands.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/6/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import ios_system

/// All available commands.
var Commands: [CommandHelp] {
    var commands = [CommandHelp]()
    
    for command in commandsAsArray() as? [String] ?? [] {
        var completionType = CommandHelp.CompletionType.none
        if operatesOn(command) == "file" {
            completionType = .file
        } else if operatesOn(command) == "directory" {
            completionType = .directory
        }
        var commandHelp = CommandHelp(commandName: command, commandInput: completionType)
        commands.append(commandHelp)
        if command == "chmod" {
            commandHelp.flags.insert("+r", at: 0)
            commandHelp.flags.insert("+w", at: 0)
            commandHelp.flags.insert("+x", at: 0)
        }
    }
    commands.append(CommandHelp(commandName: "clear", commandInput: .none))
    commands.append(CommandHelp(commandName: "sh", commandInput: .file))
    commands.append(CommandHelp(commandName: "help", commandInput: .none))
    commands.append(CommandHelp(commandName: "exit", commandInput: .none))
    
    return commands
}
