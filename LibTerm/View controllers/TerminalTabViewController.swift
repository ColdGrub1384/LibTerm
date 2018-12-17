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
import ObjectUserDefaults

/// The tab view controller containing terminals.
class TerminalTabViewController: TabViewController {
    
    private var newTerminal: LTTerminalViewController {
        return LTTerminalViewController.makeTerminal()
    }

    /// Saved tabs.
    static let tabs = ObjectUserDefaults.standard.item(forKey: "tabs")
    
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
    
    /// Set to `false` to disable opening tabs.
    var canOpenTabs = true {
        didSet {
            if !canOpenTabs && navigationItem.rightBarButtonItems?.count == 2 {
                navigationItem.rightBarButtonItems?.remove(at: 1)
            } else {
                setupBarItems()
            }
        }
    }
    
    private func setupBarItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Settings"), style: .plain, target: self, action: #selector(showSettings(_:)))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: #imageLiteral(resourceName: "Organize"), style: .plain, target: self, action: #selector(cd(_:))), UIBarButtonItem(image: #imageLiteral(resourceName: "Add"), style: .plain, target: self, action: #selector(addTab))]
    }
    
    /// Saves tabs on the disk.
    func saveTabs() {
        var bookmarks = [Data]()
        for vc in viewControllers {
            if let term = vc as? LTTerminalViewController, let bookmarkData = term.bookmarkData {
                bookmarks.append(bookmarkData)
            }
        }
        TerminalTabViewController.tabs.arrayValue = bookmarks
    }
    
    // MARK: - Tab view controller
    
    required init(theme: TabViewTheme) {
        super.init(theme: theme)
        
        view.tintColor = LTTerminalViewController.Preferences().foregroundColor
        
        setupBarItems()
        
        if let bookmarks = TerminalTabViewController.tabs.arrayValue as? [Data], !bookmarks.isEmpty {
            var terminals = [LTTerminalViewController]()
            
            for bookmark in bookmarks {
                var isStale = false
                guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) else {
                    viewControllers = [newTerminal]
                    return
                }
                
                _ = url.startAccessingSecurityScopedResource()
                
                let term = newTerminal
                term.loadViewIfNeeded()
                term.url = url
                term.title = url.lastPathComponent
                terminals.append(term)
            }
            
            viewControllers = terminals
        } else {
            viewControllers = [newTerminal]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func closeTab(_ tab: UIViewController) {
        
        (tab as? LTTerminalViewController)?.shell.killCommand()
        
        super.closeTab(tab)
        
        saveTabs()
    }
    
    override func activateTab(_ tab: UIViewController) {
        super.activateTab(tab)
        
        saveTabs()
    }
}


