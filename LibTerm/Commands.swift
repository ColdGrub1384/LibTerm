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
        commands.append(CommandHelp(commandName: command, commandInput: completionType))
    }
    commands.append(CommandHelp(commandName: "clear", commandInput: .none))
    commands.append(CommandHelp(commandName: "sh", commandInput: .file))
    commands.append(CommandHelp(commandName: "help", commandInput: .none))
    commands.append(CommandHelp(commandName: "exit", commandInput: .none))
    
    return commands
}
