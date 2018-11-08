//
//  help.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
#if !targetEnvironment(simulator)
import ios_system
#endif

/// The `help` command.
func helpMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
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
