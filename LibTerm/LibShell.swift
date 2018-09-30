//
//  LibShell.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ios_system

/// The shell for executing commands.
class LibShell {
    
    /// Initialize the shell.
    init() {
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
    }
    
    /// The IO object for reading output and writting input.
    let io = IO()
    
    /// `true` if a command is actually running on this shell.
    var isCommandRunning = false
    
    /// Writes the prompt to the terminal.
    func input() {
        DispatchQueue.main.async {
            self.io.terminal?.input(prompt: "\(UIDevice.current.name) $ ")
        }
    }
    
    /// Run given command.
    ///
    /// - Parameters:
    ///     - command: The command to run.
    ///
    /// - Returns: The exit code.
    @discardableResult func run(command: String) -> Int32 {
        ios_switchSession(io.ios_stdout)
        ios_setStreams(io.ios_stdin, io.ios_stdout, io.ios_stderr)
        
        thread_stderr = nil
        thread_stdout = nil
                
        isCommandRunning = true
        
        let returnCode = ios_system(command.cValue)
        
        isCommandRunning = false
        
        fflush(io.ios_stderr)
        fflush(io.ios_stdout)
                        
        return returnCode
    }
}
