//
//  exit.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/6/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The `exit` command.
func exitMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    var exitCode: Int32 = 0
    if argc > 1, let code = Int32(argv[1]) {
        exitCode = code
    }
    
    DispatchQueue.main.async {
        #if FRAMEWORK
        // Shows bookmarks in Pisth
        let showBookmarks = Selector(("showBookmarks"))
        if let delegate = UIApplication.shared.delegate, delegate.responds(to: showBookmarks) {
            delegate.perform(showBookmarks)
        }
        #else
        let tabVC = UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController
        if tabVC?.viewControllers.count == 1 {
            exit(exitCode)
        } else if let visible = tabVC?.visibleViewController {
            tabVC?.closeTab(visible)
        }
        #endif
    }
    return 0
}
