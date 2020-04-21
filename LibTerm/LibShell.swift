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
    
    guard let shell = io.terminal?.shell else {
        return 1
    }
    
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
        return libshellMain(argc: 1, argv: ["-h"], io: io)
        #else
        DispatchQueue.main.async {
            (io.terminal?.parent as? TerminalTabViewController)?.addTab()
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
                var components = instruction.components(separatedBy: .whitespaces)
                while components.first?.isEmpty == true {
                    components.remove(at: 0)
                }
                if components.count > 0, components[0] == "exit" { // Exit
                    if components.count > 1 {
                        exit()
                        return Int32(components[1]) ?? 0
                    } else {
                        exit()
                        return 0
                    }
                }
                shell.run(command: instruction, appendToHistory: false)
            }
        }
    } catch {
        fputs("\(argv[0]): \(error.localizedDescription)\n", io.stdout)
        return 1
    }
    
    exit()
    return 0
}

fileprivate func parseArgs(_ args: inout [String]) {
    
    func parse(quote: String) {
        var parsedArgs = [String]()
        
        var currentArg = ""
        
        for arg in args {
            
            if arg.hasPrefix(quote) && arg.hasSuffix(quote) && !arg.contains(" ") {
                var argument = arg
                if argument.count > 1 {
                    argument.removeFirst()
                }
                if argument.count > 1 {
                    argument.removeLast()
                }
                parsedArgs.append(argument.replacingOccurrences(of: ";", with: "%SEMICOLON%"))
                continue
            }
            
            if arg.isEmpty {
                continue
            }
            
            if arg.hasPrefix(quote) {
                
                if currentArg.isEmpty {
                    
                    currentArg = arg
                    currentArg.removeFirst()
                    
                } else {
                    
                    currentArg.append(" " + arg)
                    
                }
                
            } else if arg.hasSuffix(quote) {
                
                if currentArg.isEmpty {
                    
                    currentArg.append(arg)
                    
                } else {
                    
                    currentArg = currentArg.replacingOccurrences(of: ";", with: "%SEMICOLON%")
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
            if currentArg.hasSuffix(quote) {
                currentArg.removeLast()
            }
            parsedArgs.append(currentArg)
        }
        
        args = parsedArgs
    }
    
    parse(quote: "'")
    parse(quote: "\"")
}

/// The shell for executing commands.
open class LibShell {
    
    /// Initialize the shell.
    public init() {
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
        initializeEnvironment()
    }
    
    private var _shared_history: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: "history") ?? []
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "history")
            UserDefaults.standard.synchronize()
        }
    }
    
    private var _shell_history = [String]()
    
    /// The commands history.
    open var history: [String] {
        get {
            if #available(iOS 13.0, *) {
                return _shell_history
            } else {
                return _shared_history
            }
        }
        
        set {
            if #available(iOS 13.0, *) {
                _shell_history = newValue
            } else {
                _shared_history = newValue
            }
        }
    }
    
    /// The IO object for reading output and writting input.
    open var io: LTIO?
    
    /// `true` if a command is actually running on this shell.
    public var isCommandRunning = false {
        didSet {
            DispatchQueue.main.async {
                self.io?.terminal?.updateSuggestions()
            }
        }
    }
    
    /// `true` if a builtin is running.
    public var isBuiltinRunning = false
    
    /// Builtin commands per name and functions.
    open var builtins: [String:LTCommand] {
        var commands = ["clear" : clearMain, "help" : helpMain, "sh" : libshellMain, "exit" : exitMain, "open" : openMain, "credits" : creditsMain, "jsc": jscMain]
        #if !FRAMEWORK
            commands["package"] = packageMain
            commands["edit"] = editMain
        #endif
        #if targetEnvironment(simulator)
        commands["screenshot"] = screenshotMain
        #endif
        return commands
    }
    
    /// Writes the prompt to the terminal.
    public func input() {
        DispatchQueue.main.async {
            if let ps1 = getenv("PS1") {
                self.io?.terminal?.input(prompt: String(cString: ps1))
            } else {
                self.io?.terminal?.input(prompt: "\(UIDevice.current.name) $ ")
            }
        }
    }
    
    /// Shell's variables.
    open var variables = [String:String]()
    
    /// Closes `stdin`.
    @objc public func sendEOF() {
        
        guard let io = io else {
            return
        }
        
        if #available(iOS 13.0, *) {
            try? io.inputPipe.fileHandleForWriting.close()
        } else {
            io.inputPipe.fileHandleForWriting.closeFile()
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            if let term = io.terminal {
                self.io = LTIO(terminal: term)
            }
        }
    }
    
    /// Kills the current running command.
    @objc public func killCommand() {
        guard isCommandRunning, let io = self.io else {
            return
        }
        
        if let queue = io.terminal?.thread {
            queue.async {
                fputs("\n", io.stdin)
                fflush(io.stdin)
                ios_kill()
                Thread.current.cancel()
            }
        } else {
            fputs("\n", io.stdin)
            fflush(io.stdin)
            ios_kill()
        }
        io.inputPipe = Pipe()
        io.stdin = fdopen(io.inputPipe.fileHandleForReading.fileDescriptor, "r")
        isCommandRunning = false
    }
    
    // MARK: - Running
    
    /// Run given command.
    ///
    /// - Parameters:
    ///     - command: The command to run.
    ///     - appendToHistory: If set to `false`, command will not be added to the history.
    ///
    /// - Returns: The exit code.
    @discardableResult open func run(command: String, appendToHistory: Bool = true) -> Int32 {
        
        putenv("TERM=xterm-color".cValue)
        
        guard let io = self.io else {
            return 1
        }
        
        if appendToHistory {
            addToHistory(command)
        }
        
        thread_stdout = nil
        thread_stderr = nil
        thread_stdin = nil
        
        io.inputPipe = Pipe()
        io.stdin = fdopen(io.inputPipe.fileHandleForReading.fileDescriptor, "r")
        ios_switchSession(io.stdout)
        
        DispatchQueue.main.async {
            io.terminal?.updateSize()
        }
        
        isCommandRunning = true
        
        defer {
            isCommandRunning = false
        }
        
        var command_ = commandByReplacingVariables(command)
        if command_.split(separator: " ").first == "clang" {
            command_ = command_.replacingFirstOccurrence(of: "clang", with: "clang -fcolor-diagnostics")
        }
        
        if command_.split(separator: " ").first == "python3" {
            command_ = command_.replacingFirstOccurrence(of: "python3", with: "python")
        }
        
        var arguments = command_.arguments
        parseArgs(&arguments)
        guard arguments.count > 0 else {
            return 0
        }
        
        setStreams(arguments: arguments, io: io)
        
        if let repl = setupPython(arguments: arguments) {
            return repl
        } else if let variableSet = setVariablesIfNeeded(command: command_) {
            return variableSet
        } else if let ranScript = tryToRunScript(arguments: &arguments) {
            return ranScript
        } else if builtins.keys.contains(arguments[0]) {
            isBuiltinRunning = true
            defer {
                isBuiltinRunning = false
            }
            return builtins[arguments[0]]?(arguments.count, arguments, io) ?? 1
        }
        
        let retValue = ios_system(command_.cValue)
        
        variables["?"] = "\(retValue)"
        
        return retValue
    }
    
    private func addToHistory(_ command: String) {
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
        if !history.contains(historyCommand), !historyCommand.isEmpty {
            append(command: historyCommand)
        } else if let i = history.firstIndex(of: historyCommand) {
            history.remove(at: i)
            append(command: historyCommand)
        }
    }
    
    private func setStreams(arguments: [String], io: LTIO) {
        if arguments.first == "python" || arguments.first == "python3" || arguments.first == "python2" || arguments.first == "lua" || arguments.first == "bc" || arguments.first == "dc" { // Redirect stderr to stdout and reset input
            
            io.inputPipe = Pipe()
            io.stdin = fdopen(io.inputPipe.fileHandleForReading.fileDescriptor, "r")
            
            let _stdin = io.stdin
            
            defer {
                stdin = _stdin ?? stdin
            }
            
            ios_setStreams(io.stdin, io.stdout, io.stdout)
            
            stdin = io.stdin ?? stdin
        } else {
            ios_setStreams(io.stdin, io.stdout, io.stderr)
        }
    }
    
    private func setVariablesIfNeeded(command: String) -> Int32? {
        let setterComponents = command.components(separatedBy: "=")
        if setterComponents.count > 1 {
            if !setterComponents[0].contains(" ") {
                var value = setterComponents
                value.removeFirst()
                variables[setterComponents[0]] = value.joined(separator: "=")
                return 0
            }
        }
        
        return nil
    }
    
    private func commandByReplacingVariables(_ command: String) -> String {
        var command_ = command
        for variable in variables {
            command_ = command_.replacingOccurrences(of: "$\(variable.key)", with: variable.value)
        }
        
        while command_.hasPrefix(" ") {
            command_.removeFirst()
        }
        
        return command_
    }
    
    private enum PythonVersion {
        
        case v2_7
        case v3_7
    }
    
    private func setPythonEnvironment(version: PythonVersion) {
        
        guard let py2Path = Bundle.main.path(forResource: "python27", ofType: "zip") else {
            fatalError()
        }
        
        let py2SitePackages = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("site-packages2").path
        
        guard let py3Path = Bundle.main.path(forResource: "python37", ofType: "zip") else {
            fatalError()
        }
        
        let py3SitePackages = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("site-packages3").path
        
        let bundledSitePackages = Bundle.main.bundleURL.appendingPathComponent("site-packages").path
        let bundledSitePackages3 = Bundle.main.bundleURL.appendingPathComponent("site-packages3").path
        
        putenv("PYTHONHOME=\(Bundle.main.bundlePath)".cValue)
        
        if version == .v2_7 {
            putenv("PYTHONPATH=\(py2SitePackages):\(py2Path):\(bundledSitePackages)".cValue)
        } else if version == .v3_7 {
            putenv("PYTHONPATH=\(py3SitePackages):\(py3Path):\(bundledSitePackages):\(bundledSitePackages3)".cValue)
        }
    }
    
    private func setupPython(arguments: [String]) -> Int32? {
        // When Python is called without arguments, it freezes instead of running the REPL
        if arguments.first == "python" || arguments.first == "python3" {
            setPythonEnvironment(version: .v3_7)
            if arguments == ["python"] {
                return ios_system("python \(runREPL)")
            }
        } else if arguments.first == "python2" {
            setPythonEnvironment(version: .v2_7)
            if arguments == ["python2"] {
                return ios_system("python2 \(runREPL)")
            }
        }
        return nil
    }
    
    private func tryToRunScript(arguments: inout [String]) -> Int32? {
        // Run Python scripts located in ~/Library/bin
        let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("bin")
        
        let url: URL
        let command: String
        
        let llURL = scriptsDirectory.appendingPathComponent(arguments[0]+".ll")
        let bcURL = scriptsDirectory.appendingPathComponent(arguments[0]+".bc")
        let binURL = scriptsDirectory.appendingPathComponent(arguments[0])
        let scriptURL = scriptsDirectory.appendingPathComponent(arguments[0]+".py")
        
        if FileManager.default.fileExists(atPath: binURL.path) {
            url = binURL
            command = "lli"
        } else if FileManager.default.fileExists(atPath: llURL.path) {
            url = llURL
            command = "lli"
        } else if FileManager.default.fileExists(atPath: bcURL.path) {
            url = bcURL
            command = "lli"
        } else {
            url = scriptURL
            command = "python"
            setPythonEnvironment(version: .v3_7)
        }
        
        if FileManager.default.fileExists(atPath: url.path) {
            arguments.insert(command, at: 0)
            arguments.remove(at: 1)
            arguments.insert(url.path, at: 1)
            
            return run(command: arguments.joined(separator: " "), appendToHistory: false)
        } else {
            return nil
        }
    }
    
    private let runREPL = "-c 'from code import interact; interact()'"
}
