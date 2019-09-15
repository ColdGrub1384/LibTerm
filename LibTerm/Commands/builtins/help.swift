//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system

/// The last login date.
var lastLogin: Date? {
    get {
        return UserDefaults.standard.object(forKey: "lastLogin") as? Date
    }
    
    set {
        UserDefaults.standard.set(newValue, forKey: "lastLogin")
        UserDefaults.standard.synchronize()
    }
}

/// The `help` command.
func helpMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    if argv.contains("--compiling") || argv.contains("compiling") {
        
        var range = NSRange(location: 0, length: 0)
        DispatchQueue.main.sync {
            range = io.terminal?.terminalTextView.selectedRange ?? range
        }
        
        let compiling = "To compile C code, use the 'clang' command. Code cannot be compiled as an executable binary but has to be compiled into LLVM Intermediate Representation (LLVM IR). Then, the LLVM IR code will be interpreted by the 'lli' command. To compile code:\n\n$ clang -S -emit-llvm <other options> <C file to compile>\n\nThis will generate a '.ll' file, which is in LLVM IR format. To run the code, use the 'lli' command.\n\n$ lli <file>.ll\n\nThat will run the 'main' function.\n\nA '.ll' file can be executed or multiple '.ll' files can be merged into one, so we can code a program with multiple sources. You can use the 'llvm-link' command to \"merge\" multiple files.\n\n$ clang -S -emit-llvm helper.c\n$ clang -S -emit-llvm main.c\n$ llvm-link -o program.bc *.ll\n$ lli 'program.bc'\n\nYou can put your programs in '~/Library/bin' and run them directly by their name. If the program has the 'll' or 'bc' file extension, don't type the file extension."
        
        guard let rowsStr = ProcessInfo.processInfo.environment["LINES"], var rows = Int(rowsStr) else {
            fputs(compiling, stdout)
            return 0
        }
        
        rows -= 6
        
        let lines = compiling.components(separatedBy: "\n")
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
            
            if currentLine <= lines.count-1 {
                for i in currentLine...lines.count-1 {
                    if lines.indices.contains(i) {
                        currentLine += 1
                        fputs(lines[i]+"\n", io.stdout)
                    } else {
                        break
                    }
                }
            }
            
            semaphore.signal()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1.4, execute: {
            io.terminal?.terminalTextView.scrollRangeToVisible(range)
        })
        
        semaphore.wait()
        
        return 0
    }
    
    if argv.contains("--restored") || argv.contains("-r") {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        fputs("\n\nRestored on \(formatter.string(from: Date()))\n\n", io.stdout)
        return 0
    }
    
    var helpText: String
    
    #if FRAMEWORK
    helpText = ""
    #else
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        helpText = "LibTerm version \(version) (\(build)), \(formatter.string(from: BuildDate))\n\n"
    } else {
        helpText = "Unknown version\n\n"
    }
    #endif
    
    if argv.contains("--version") {
        fputs(helpText, io.stdout)
        return 0
    }
    
    if argv.contains("--startup") || argv.contains("-s") {
        if let lastLogin = lastLogin {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            helpText = helpText.replacingOccurrences(of: "\n", with: "")
            helpText += "\nLast login: \(formatter.string(from: lastLogin))\n"
        }
        fputs(helpText, io.stdout)
        return 0
    }
    
    for command in LTHelp {
        if command != LTHelp.last {
            helpText += "\(command.commandName), "
        } else {
            helpText += "\(command.commandName)\n"
        }
    }
    
    helpText += "\nUse the 'package' command to install third party commands.\n"
    helpText += "\n\nWith LibTerm, you can compile and run C and C++ code with the 'clang' and 'lli' commands. Type 'help compiling' for more information.\n"
    fputs(helpText, io.stdout)
        
    return 0
}
