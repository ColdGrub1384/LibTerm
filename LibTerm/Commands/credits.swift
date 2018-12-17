//
//  credits.swift
//  LibTerm
//
//  Created by Adrian Labbe on 12/17/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation

/// The `credits` command.
func creditsMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    guard let creditsURL = Bundle.main.url(forResource: "credits", withExtension: nil) else {
        return 1
    }
    
    _ = helpMain(argc: 2, argv: ["help", "--version"], io: io)
    
    do {
        let credits = try String(contentsOf: creditsURL).replacingOccurrences(of: "PLAIN", with: "\u{001b}[0m").replacingOccurrences(of: "BOLD", with: "\u{001b}[1m")
        
        guard let rowsStr = ProcessInfo.processInfo.environment["ROWS"], var rows = Int(rowsStr) else {
            fputs(credits, stdout)
            return 0
        }
        
        rows -= 6
        
        let lines = credits.components(separatedBy: "\n")
        var currentLine = 0
        
        for i in 0...rows {
            if lines.indices.contains(i) {
                currentLine += 1
                fputs(lines[i]+"\n", io.stdout)
            } else {
                break
            }
        }
        
        while currentLine < lines.count-1 {
            currentLine += 1
            
            var byte: Int8 = 0
            _ = read(fileno(io.stdin), &byte, 1)
            
            guard lines.indices.contains(currentLine) else {
                break
            }
            
            if lines[currentLine].replacingOccurrences(of: " ", with: "").isEmpty {
                fputs("\n", io.stdout)
                currentLine += 1
            }
            
            guard lines.indices.contains(currentLine) else {
                break
            }
            
            fputs(lines[currentLine], io.stdout)
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                io.terminal?.terminalTextView.scrollToBottom()
            }
        }
    } catch {
        fputs("\(error.localizedDescription)\n", io.stderr)
        return 1
    }
    
    return 0
}
