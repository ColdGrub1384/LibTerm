//
//  Commands.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/6/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

#if !targetEnvironment(simulator)
import ios_system
#endif

/// All available commands.
public var LTHelp: [LTCommandHelp] = {
    
    #if targetEnvironment(simulator)
    return []
    #else
    var commands = [LTCommandHelp]()
    
    for command in commandsAsArray() as? [String] ?? [] {
        var completionType = LTCommandHelp.CompletionType.none
        if operatesOn(command) == "file" {
            completionType = .file
        } else if operatesOn(command) == "directory" {
            completionType = .directory
        }
        var commandHelp = LTCommandHelp(commandName: command, commandInput: completionType)
        if command == "chmod" {
            commandHelp.flags.insert("+r", at: 0)
            commandHelp.flags.insert("+w", at: 0)
            commandHelp.flags.insert("+x", at: 0)
        }
        commands.append(commandHelp)
    }
    commands.append(LTCommandHelp(commandName: "clear", commandInput: .none))
    commands.append(LTCommandHelp(commandName: "sh", commandInput: .file))
    commands.append(LTCommandHelp(commandName: "help", commandInput: .none))
    commands.append(LTCommandHelp(commandName: "exit", commandInput: .none))
    commands.append(LTCommandHelp(commandName: "open", commandInput: .file))
    
    #if !FRAMEWORK
        var package = LTCommandHelp(commandName: "package", commandInput: .none)
        package.flags = ["install", "remove", "source"]
        commands.append(package)
    #endif
    
    return commands
    #endif
}()
