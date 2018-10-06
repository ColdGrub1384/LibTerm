//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system

/// A structure representing a command for helping the user.
struct CommandHelp: Equatable {
    
    /// The command name.
    var commandName: String
    
    /// The argument type the commands supports. `.none`, `.file` or `.directory`.
    var commandInput: CompletionType {
        didSet {
            if commandInput == .history || commandInput == .command {
                fatalError("History and command aren't supported for a command input yet.")
            }
        }
    }
    
    /// A structure representing completions type available for a command.
    enum CompletionType {
        
        /// No completion
        case none
        
        /// Show the history.
        case history
        
        /// Show commands matching by the user's input.
        case command
        
        /// Show files and directories in the current directory.
        case file
        
        /// Show directories in the current directory.
        case directory
    }
    
    static func == (lhs: CommandHelp, rhs: CommandHelp) -> Bool {
        return (lhs.commandName == rhs.commandName)
    }
}

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
    return commands
}

/// The `help` command.
func helpMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var helpText = ""
    for command in Commands {
        if command != Commands.last {
            helpText += "\(command.commandName), "
        } else {
            helpText += "\(command.commandName)\n"
        }
    }
    
    shell.io?.outputPipe.fileHandleForWriting.write(helpText)
    
    return 0
}
