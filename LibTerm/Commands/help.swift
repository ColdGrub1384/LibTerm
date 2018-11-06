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
func helpMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    var helpText = ""
    for command in LTHelp {
        if command != LTHelp.last {
            helpText += "\(command.commandName), "
        } else {
            helpText += "\(command.commandName)\n"
        }
    }
    
    helpText += "\nInstall more commands by typing `package install <Package name>`\n"
    fputs(helpText, io.stdout)
    
    return 0
}
