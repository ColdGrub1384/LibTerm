//
//  IO.swift
//  Pyto
//
//  Created by Adrian Labbe on 9/24/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import UIKit

/// A class for managing input and output.
@objc class IO: NSObject {
    
    /// Initialize for writting to the given terminal.
    ///
    /// - Parameters:
    ///     - terminal: The terminal that receives output.
    init(terminal: TerminalViewController) {
        super.init()
        self.terminal = terminal
        ios_stdout = fdopen(outputPipe.fileHandleForWriting.fileDescriptor, "w")
        ios_stderr = ios_stdout
        ios_stdin = fdopen(inputPipe.fileHandleForReading.fileDescriptor, "r")
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            if let str = String(data: handle.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.terminal?.terminalTextView.text += str
                    self.terminal?.textViewDidChange(self.terminal!.terminalTextView)
                }
            }
        }
        setbuf(ios_stdout!, nil)
        setbuf(ios_stderr!, nil)
    }
    
    /// The stdin file.
    var ios_stdin: UnsafeMutablePointer<FILE>?
    
    /// The stdout file.
    var ios_stdout: UnsafeMutablePointer<FILE>?
    
    /// The stderr file.
    var ios_stderr: UnsafeMutablePointer<FILE>?
    
    /// The output pipe.
    var outputPipe = Pipe()
    
    /// The input pipe.
    var inputPipe = Pipe()
    
    /// The terminal that receives output.
    var terminal: TerminalViewController?
    
    /// Sends given input for current running `ios_system` command.
    ///
    /// - Parameters:
    ///     - input: Input to send.
    func send(input: String) {
        if let data = input.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
        }
    }
}
