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

func libshellMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    if argc == 1 {
        DispatchQueue.main.async {
            (UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController)?.addTab()
        }
        return 0
    }
    var args = argv
    args.removeFirst()
    
    if args == ["-h"] || args == ["--help"] {
        shell.io?.outputPipe.fileHandleForWriting.write("usage: \(argv[0]) [script args]\n".data(using: .utf8) ?? Data())
    }
    
    do {
        let scriptPath = URL(fileURLWithPath: (args[0] as NSString).expandingTildeInPath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        
        let script = try String(contentsOf: scriptPath)
        
        putenv("@=\(args.joined(separator: ":"))".cValue)
        var i = 0
        for arg in args {
            putenv("\(i)=\(arg)".cValue)
            i += 1
        }
        
        for instruction_ in script.components(separatedBy: .newlines) {
            for instruction in instruction_.components(separatedBy: ";") {
                shell.run(command: instruction)
            }
        }
    } catch {
        shell.io?.outputPipe.fileHandleForWriting.write("\(argv[0]): \(error.localizedDescription)\n".data(using: .utf8) ?? Data())
        return 1
    }
    
    putenv("@".cValue)
    var i = 0
    for _ in args {
        putenv("\(i)=".cValue)
        i += 1
    }
    
    return 0
}

/// The shell for executing commands.
class LibShell {
    
    /// Initialize the shell.
    init() {
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
        initializeEnvironment()
    }
    
    /// The commands history.
    var history: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: "history") ?? []
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "history")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// The IO object for reading output and writting input.
    var io: IO?
    
    /// `true` if a command is actually running on this shell.
    var isCommandRunning = false
    
    /// Builtin commands per name and functions.
    let builtins: [String:Command] = ["clear" : clearMain, "help" : helpMain, "ssh" : sshMain, "sftp" : sshMain, "sh" : libshellMain]
    
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
        
        if components == ["python"] {
            ios_system("python -c 'import code; code.interact()'")
            return 0
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
            
            parsedArgs.insert(command.components(separatedBy: .whitespaces)[0], at: 0)
            
            returnCode = builtins[program]?(parsedArgs.count, parsedArgs, self) ?? 1
        } else {
            returnCode = ios_system(command.cValue)
        }
        
        isCommandRunning = false
        
        if returnCode == 0 {
            func append(command: String) {
                // Remove useless spaces
                var command_ = command
                while command_.hasSuffix(" ") {
                    command_ = String(command.dropLast())
                }
                
                history.append(command_)
            }
            if !history.contains(command) {
                append(command: command)
            } else if let i = history.firstIndex(of: command) {
                history.remove(at: i)
                append(command: command)
            }
        }
        
        return returnCode
    }
}
