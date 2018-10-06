//
//  IO.swift
//  Pyto
//
//  Created by Adrian Labbe on 9/24/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import UIKit

extension FileHandle {
    
    /// Writes given string to the file.
    ///
    /// - Parameters:
    ///     - str: Text to print.
    func write(_ str: String) {
        if let data = str.data(using: .utf8) {
            write(data)
        }
    }
}

/// A class for managing input and output.
class IO: ParserDelegate {
    
    /// Initialize for writting to the given terminal.
    ///
    /// - Parameters:
    ///     - terminal: The terminal that receives output.
    init(terminal: TerminalViewController) {
        self.terminal = terminal
        ios_stdout = fdopen(outputPipe.fileHandleForWriting.fileDescriptor, "w")
        ios_stderr = ios_stdout
        ios_stdin = fdopen(inputPipe.fileHandleForReading.fileDescriptor, "r")
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            self.parser.delegate = self
            self.parser.parse(handle.availableData)
        }
        setbuf(ios_stdout!, nil)
        setbuf(ios_stderr!, nil)
    }
    
    private let parser = Parser()
    
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
    
    // MARK: - Parser delegate
    
    func parser(_ parser: Parser, didReceiveString string: NSAttributedString) {
        DispatchQueue.main.async {
            guard let term = self.terminal else {
                return
            }
            
            let attributedString = NSMutableAttributedString(attributedString: term.terminalTextView.attributedText ?? NSAttributedString())
            attributedString.append(string)
            term.terminalTextView.attributedText = attributedString
        }
    }
    
    func parserDidEndTransmission(_ parser: Parser) {}
}
