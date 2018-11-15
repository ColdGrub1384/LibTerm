//
//  TerminalTabViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/3/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import TabView
import ios_system

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
    
    /// Shows settings.
    @objc func showSettings(_ sender: Any) {
        guard let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController()  as? SettingsTableViewController else {
            return
        }
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.barStyle = .black
        navVC.modalPresentationStyle = .formSheet
        present(navVC, animated: true, completion: nil)
    }
    
    // MARK: - Tab view controller
    
    required init(theme: TabViewTheme) {
        super.init(theme: theme)
        
        view.tintColor = LTTerminalViewController.Preferences().foregroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(showSettings(_:)))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "Organize"), style: .plain, target: self, action: #selector(cd(_:))), UIBarButtonItem(image: #imageLiteral(resourceName: "Add"), style: .plain, target: self, action: #selector(addTab))]
        
        viewControllers = [newTerminal]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func closeTab(_ tab: UIViewController) {
        
        (tab as? LTTerminalViewController)?.shell.killCommand()
        
        super.closeTab(tab)
    }
}


