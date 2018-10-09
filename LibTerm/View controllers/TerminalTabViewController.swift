//
//  TerminalTabViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/3/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import TabView

/// The tab view controller containing terminals.
class TerminalTabViewController: TabViewController {
    
    private var newTerminal: LTTerminalViewController {
        return UIStoryboard(name: "Terminal", bundle: Bundle.main).instantiateInitialViewController() as! LTTerminalViewController
    }
    
    /// Open a new terminal.
    @objc func addTab() {
        activateTab(newTerminal)
    }
    
    /// Change current working directory.
    @objc func cd(_ sender: Any) {
        (visibleViewController as? LTTerminalViewController)?.cd()
    }
    
    // MARK: - Tab view controller
    
    required init(theme: TabViewTheme) {
        super.init(theme: theme)
        
        view.tintColor = LTForegroundColor
        
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "Organize"), style: .plain, target: self, action: #selector(cd(_:))), UIBarButtonItem(image: #imageLiteral(resourceName: "Add"), style: .plain, target: self, action: #selector(addTab))]
        
        viewControllers = [newTerminal]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


