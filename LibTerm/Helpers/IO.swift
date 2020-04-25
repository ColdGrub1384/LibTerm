//
//  IO.swift
//  Pyto
//
//  Created by Adrian Labbe on 9/24/18.
//  Copyright © 2018 Adrian Labbé. All rights reserved.
//

import UIKit
import ios_system

public extension FileHandle {
    
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
public class LTIO: ParserDelegate {
    
    /// The number of operations the parser is performing.
    public var parserQueue = 0
    
    /// Initialize for writting to the given terminal.
    ///
    /// - Parameters:
    ///     - terminal: The terminal that receives output.
    public init(terminal: LTTerminalViewController) {
                
        self.terminal = terminal
        
        stdout = fdopen(outputPipe.fileHandleForWriting.fileDescriptor, "w")
        stderr = fdopen(errorPipe.fileHandleForWriting.fileDescriptor, "w")
        stdin = fdopen(inputPipe.fileHandleForReading.fileDescriptor, "r")
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            self.parserQueue += 1
            self.outputParser.delegate = self
            self.outputParser.parse(handle.availableData)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            
            let data = handle.availableData
            if var str = String(data: data, encoding: .utf8), !str.isEmpty {
                str.removeLast()
                guard !str.hasPrefix("Freeing unary") && !str.hasPrefix("Freeing leaf") && !str.hasPrefix("Freeing tree") && str.components(separatedBy: " ").last?.count != 8 else {
                    return
                }
            }
            
            self.parserQueue += 1
            if let progname = ios_progname(), String(cString: progname) == "python" || String(cString: progname) == "bc" || String(cString: progname) == "clang" {
                self.outputParser.delegate = self
                self.outputParser.parse(data)
            } else {
                self.errorParser.delegate = self
                self.errorParser.parse(data)
            }
        }
        
        setbuf(stdout!, nil)
        setbuf(stderr!, nil)
    }
    
    private let outputParser = Parser()
    private let errorParser = Parser()
    
    /// The stdin file.
    public var stdin: UnsafeMutablePointer<FILE>?
    
    /// The stdout file.
    public var stdout: UnsafeMutablePointer<FILE>?
    
    /// The stderr file.
    public var stderr: UnsafeMutablePointer<FILE>?
    
    /// The output pipe.
    public var outputPipe = Pipe()
    
    /// The error pipe.
    public var errorPipe = Pipe()
    
    /// The input pipe.
    public var inputPipe = Pipe()
    
    /// The terminal that receives output.
    public var terminal: LTTerminalViewController?
    
    /// Sends given input for current running `ios_system` command.
    ///
    /// - Parameters:
    ///     - input: Input to send.
    public func send(input: String) {
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
            
            if parser === self.errorParser {
                var attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: attributedString.length))
                attributes[.foregroundColor] = ANSIForegroundColor.red.color
                attributedString.append(NSAttributedString(string: string.string, attributes: attributes))
            } else {
                attributedString.append(string)
            }
            
            term.terminalTextView.attributedText = attributedString
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                term.terminalTextView.scrollToBottom()
            })
            
            self.parserQueue -= 1
        }
    }
    
    func parserDidEndTransmission(_ parser: Parser) {}
}
