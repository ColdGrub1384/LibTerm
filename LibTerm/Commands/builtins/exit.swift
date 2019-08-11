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
    
    DispatchQueue.main.async {
        #if FRAMEWORK
        // Shows bookmarks in Pisth
        let showBookmarks = Selector(("showBookmarks"))
        if let delegate = UIApplication.shared.delegate, delegate.responds(to: showBookmarks) {
            delegate.perform(showBookmarks)
        }
        #else
        let tabVC = io.terminal?.parent as? TerminalTabViewController
        
        guard let visible = tabVC?.visibleViewController else {
            return
        }
        
        tabVC?.closeTab(visible)
        #endif
    }
    return 0
}
