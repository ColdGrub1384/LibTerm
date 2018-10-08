//
//  CommandHelp.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/6/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import ios_system

/// A structure representing a command for helping the user.
public struct CommandHelp: Equatable {
    
    /// The command name.
    public var commandName: String
    
    /// The argument type the commands supports. `.none`, `.file` or `.directory`.
    public var commandInput: CompletionType {
        didSet {
            if commandInput == .history || commandInput == .command {
                fatalError("History and command aren't supported for a command input yet.")
            }
        }
    }
    
    /// Returns flags supported by the command.
    public var flags: [String] {
        var flags_ = [String]()
        for flag in getoptString(commandName) {
            if flag != ":" {
                flags_.append("-\(flag)")
            }
        }
        return flags_
    }
    
    /// A structure representing completions type available for a command.
    public enum CompletionType {
        
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
    
    public static func == (lhs: CommandHelp, rhs: CommandHelp) -> Bool {
        return (lhs.commandName == rhs.commandName)
    }
}
