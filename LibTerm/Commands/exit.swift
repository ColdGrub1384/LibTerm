//
//  exit.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/6/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The `exit` command.
func exitMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var exitCode: Int32 = 0
    if argc > 1, let code = Int32(argv[1]) {
        exitCode = code
    }
    
    DispatchQueue.main.async {
        #if FRAMEWORK
        let tabVC = UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController
        if tabVC?.viewControllers.count == 1 {
            exit(exitCode)
        } else if let visible = tabVC?.visibleViewController {
            tabVC?.closeTab(visible)
        }#else
       // Shows bookmarks in Pisth
        let showBookmarks = Selector(("showBookmarks"))
            if let delegate = UIApplication.shared.delegate, delegate.responds(to: showBookmarks) {
                delegate.perform(showBookmarks)
        }
        #endif
    }
    return 0
}
