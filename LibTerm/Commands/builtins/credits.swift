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
    
    var range = NSRange(location: 0, length: 0)
    DispatchQueue.main.sync {
        range = io.terminal?.terminalTextView.selectedRange ?? range
    }
    
    _ = helpMain(argc: 2, argv: ["help", "--version"], io: io)
    
    do {
        let credits = try String(contentsOf: creditsURL).replacingOccurrences(of: "PLAIN", with: "\u{001b}[0m").replacingOccurrences(of: "BOLD", with: "\u{001b}[1m")
        
        guard let rowsStr = ProcessInfo.processInfo.environment["LINES"], var rows = Int(rowsStr) else {
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
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
            for i in currentLine...lines.count-1 {
                if lines.indices.contains(i) {
                    currentLine += 1
                    fputs(lines[i]+"\n", io.stdout)
                } else {
                    break
                }
            }
            
            semaphore.signal()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1.4, execute: {
            io.terminal?.terminalTextView.scrollRangeToVisible(range)
        })
        
        semaphore.wait()
    } catch {
        fputs("\(error.localizedDescription)\n", io.stderr)
        return 1
    }
    
    return 0
}
