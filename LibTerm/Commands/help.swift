//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import ios_system

/// The `help` command.
func helpMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var helpText = ""
    for command in LTHelp {
        if command != LTHelp.last {
            helpText += "\(command.commandName), "
        } else {
            helpText += "\(command.commandName)\n"
        }
    }
    
    helpText += "\nInstall more commands by typing `package install <Package name>`\n"
    
    shell.io?.outputPipe.fileHandleForWriting.write(helpText)
    
    return 0
}
