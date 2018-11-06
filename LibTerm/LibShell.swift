//
//  LibShell.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ios_system

/// Type for a builtin command. A function with argc, argv and the Input/Output object.
///
/// # Building a command
///
/// First, create a function that conforms to `LTCommand`:
///
///     func myCommand(argc: Int, argv: [String], IO: LTIO) -> Int32 {
///         return 0
///     }
/// The stdout will not be read by the terminal, so you have to write to the custom output file:
///
///     func myCommand(argc: Int, argv: [String], io: LTIO) -> Int32 {
///
///         fputs("Hello World!", io.stdout)
///
///         return 0
///     }
/// For reading input:
///
///     func myCommand(argc: Int, argv: [String], IO: LTIO) -> Int32 {
///
///         io.inputPipe.fileHandleForReading.readabilityHandler = { handle in
///             do {
///                 let input = String(data: handle.availableData, encoding: .utf8)
///             } catch {
///                 // Handle error
///             }
///         }
///
///         return 0
///     }
public typealias LTCommand = ((Int, [String], LTIO) -> Int32)

func libshellMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    var args = argv
    args.removeFirst()
    
    shell.variables["@"] = args.joined(separator: " ")
    var i = 0
    for arg in args {
        shell.variables["\(i)"] = arg
        i += 1
    }
    
    func exit() {
        shell.variables.removeValue(forKey: "@")
        var i = 0
        for _ in args {
            shell.variables.removeValue(forKey: "\(i)")
            i += 1
        }
    }
    
    if argc == 1 {
        #if FRAMEWORK
        return libshellMain(argc: 1, argv: ["-h"], shell: shell)
        #else
        DispatchQueue.main.async {
            (UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController)?.addTab()
        }
        return 0
        #endif
    }
    
    if args == ["-h"] || args == ["--help"] {
        fputs("usage: \(argv[0]) [script args]\n", io.stdout)
        return 0
    }
    
    do {
        let scriptPath = URL(fileURLWithPath: (args[0] as NSString).expandingTildeInPath, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        
        let script = try String(contentsOf: scriptPath)
        
        for instruction_ in script.components(separatedBy: .newlines) {
            for instruction in instruction_.components(separatedBy: ";") {
                let components = instruction.components(separatedBy: .whitespaces)
                if components.count > 0, components[0] == "exit" { // Exit
                    if components.count > 1 {
                        exit()
                        return Int32(components[1]) ?? 0
                    } else {
                        exit()
                        return 0
                    }
                }
                shell.run(command: instruction)
            }
        }
    } catch {
        fputs("\(argv[0]): \(error.localizedDescription)\n", io.stdout)
        return 1
    }
    
    exit()
    return 0
}

/// The shell for executing commands.
open class LibShell {
    
    /// Initialize the shell.
    public init() {
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
        initializeEnvironment()
    }
    
    /// The commands history.
    open var history: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: "history") ?? []
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "history")
            UserDefaults.standard.synchronize()
        }
    }
    
    /// The IO object for reading output and writting input.
    open var io: LTIO?
    
    /// `true` if a command is actually running on this shell.
    public var isCommandRunning = false
    
    /// Builtin commands per name and functions.
    open var builtins: [String:LTCommand] {
        var commands = ["clear" : clearMain, "help" : helpMain, "ssh" : sshMain, "sftp" : sshMain, "sh" : libshellMain, "exit" : exitMain, "open" : openMain]
        #if !FRAMEWORK
            commands["package"] = packageMain
        #endif
        return commands
    }
    
    /// Writes the prompt to the terminal.
    public func input() {
        DispatchQueue.main.async {
            self.io?.terminal?.input(prompt: "\(UIDevice.current.name) $ ")
        }
    }
    
    /// Shell's variables.
    open var variables = [String:String]()
    
    /// Run given command.
    ///
    /// - Parameters:
    ///     - command: The command to run.
    ///
    /// - Returns: The exit code.
    @discardableResult open func run(command: String) -> Int32 {
        guard let io = self.io else {
            return 1
        }
        ios_switchSession(io.stdout)
        ios_setStreams(io.stdin, io.stdout, io.stderr)
        
        thread_stderr = nil
        thread_stdout = nil
                
        isCommandRunning = true
        
        var command_ = command
        for variable in variables {
            command_ = command_.replacingOccurrences(of: "$\(variable.key)", with: variable.value)
        }
        
        var arguments = command_.arguments
        
        guard arguments.count > 0 else {
            return 0
        }
        
        if arguments == ["python"] { // When Python is called without arguments, it freezes instead of running the REPL
            return ios_system("python -c 'import code; code.interact()'")
        }
        
        let setterComponents = command.components(separatedBy: "=")
        if setterComponents.count > 1 {
            if !setterComponents[0].contains(" ") {
                var value = setterComponents
                value.removeFirst()
                variables[setterComponents[0]] = value.joined(separator: "=")
                return 0
            }
        }
        
        var returnCode: Int32
        
        // Run Python scripts located in ~/Library/scripts
        let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("scripts")
        let scriptURL = scriptsDirectory.appendingPathComponent(arguments[0]+".py")
        if FileManager.default.fileExists(atPath: scriptURL.path) {
            arguments.insert("python", at: 0)
            arguments.remove(at: 1)
            arguments.insert(scriptURL.path, at: 1)
            returnCode = ios_system(arguments.joined(separator: " ").cValue)
        } else if builtins.keys.contains(arguments[0]) {
            returnCode = builtins[arguments[0]]?(arguments.count, arguments, io) ?? 1
        } else {
            returnCode = ios_system(command_.cValue)
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
            var historyCommand = command
            while historyCommand.hasSuffix(" ") {
                historyCommand = String(historyCommand.dropLast())
            }
            if !history.contains(historyCommand) {
                append(command: historyCommand)
            } else if let i = history.firstIndex(of: historyCommand) {
                history.remove(at: i)
                append(command: historyCommand)
            }
        }
        
        return returnCode
    }
}
