//
//  LibShell.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ios_system

/// Type for a builtin command. A function with argc, argv and the shell running it.
typealias Command = ((Int, [String], LibShell) -> Int32)

/// The shell for executing commands.
class LibShell {
    
    /// Initialize the shell.
    init() {
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
    }
    
    /// The IO object for reading output and writting input.
    var io: IO?
    
    /// `true` if a command is actually running on this shell.
    var isCommandRunning = false
    
    /// Builtin commands per name and functions.
    let builtins: [String:Command] = ["clear" : clearMain, "help" : helpMain]
    
    /// Writes the prompt to the terminal.
    func input() {
        DispatchQueue.main.async {
            self.io?.terminal?.input(prompt: "\(UIDevice.current.name) $ ")
        }
    }
    
    /// Run given command.
    ///
    /// - Parameters:
    ///     - command: The command to run.
    ///
    /// - Returns: The exit code.
    @discardableResult func run(command: String) -> Int32 {
        if let io = io {
            ios_switchSession(io.ios_stdout)
            ios_setStreams(io.ios_stdin, io.ios_stdout, io.ios_stderr)
        }
        
        thread_stderr = nil
        thread_stdout = nil
                
        isCommandRunning = true
        
        let components = command.components(separatedBy: .whitespaces)
        guard components.count > 0 else {
            return 0
        }
        
        if components == ["python"], let data = "python: Python REPL is not supported by LibTerm. Download Pyto on the App Store for having the full Python 3.6. You can still running Python 2.7 scripts.\n".data(using: .utf8) {
            io?.outputPipe.fileHandleForWriting.write(data)
            return 1
        } else if components == ["lua"], let data = "lua: Lua REPL is not supported by LibTerm. You can still running scripts.\n".data(using: .utf8) {
            io?.outputPipe.fileHandleForWriting.write(data)
            return 1
        }
        
        var returnCode: Int32
        if builtins.keys.contains(components[0]) {
            
            // Separate in to command and arguments
            
            let program = components[0]
            let args = Array(components[1..<components.endIndex])
            
            var parsedArgs = [String]()
            
            var currentArg = ""
            
            for arg in args {
                
                if arg.hasPrefix("\"") {
                    
                    if currentArg.isEmpty {
                        
                        currentArg = arg
                        currentArg.removeFirst()
                        
                    } else {
                        
                        currentArg.append(" " + arg)
                        
                    }
                    
                } else if arg.hasSuffix("\"") {
                    
                    if currentArg.isEmpty {
                        
                        currentArg.append(arg)
                        
                    } else {
                        
                        currentArg.append(" " + arg)
                        currentArg.removeLast()
                        parsedArgs.append(currentArg)
                        currentArg = ""
                        
                    }
                    
                } else {
                    
                    if currentArg.isEmpty {
                        parsedArgs.append(arg)
                    } else {
                        currentArg.append(" " + arg)
                    }
                    
                }
                
            }
            
            if !currentArg.isEmpty {
                parsedArgs.append(currentArg)
            }
            
            returnCode = builtins[program]?(args.count+1, [command]+args, self) ?? 1
        } else {
            returnCode = ios_system(command.cValue)
        }
        
        isCommandRunning = false
        
        if let io = io {
            fflush(io.ios_stderr)
            fflush(io.ios_stdout)
        }
        
        return returnCode
    }
}
