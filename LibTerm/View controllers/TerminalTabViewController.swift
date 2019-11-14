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
    
    /// The index of the selected View controller.
    var selectedIndex: Int? {
        
        guard let visible = visibleViewController else {
            return nil
        }
        return viewControllers.firstIndex(of: visible)
    }
    
    /// Open a new terminal.
    @objc func addTab() {
        (visibleViewController as? LTTerminalViewController)?.url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        activateTab(newTerminal)
    }
    
    /// Closes the current visible tab.
    @objc func closeCurrentTab() {
        if let tab = visibleViewController {
            closeTab(tab)
        }
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
        
        let settingsImage: UIImage?
        if #available(iOS 13.0, *) {
            settingsImage = UIImage(systemName: "gear")
        } else {
            settingsImage = UIImage(named: "Settings")
        }
        
        let organizeImage: UIImage?
        if #available(iOS 13.0, *) {
            organizeImage = UIImage(systemName: "folder")
        } else {
            organizeImage = #imageLiteral(resourceName: "Organize")
        }
        
        let addImage: UIImage?
        if #available(iOS 13.0, *) {
            addImage = UIImage(systemName: "plus")
        } else {
            addImage = #imageLiteral(resourceName: "Add")
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(showSettings(_:)))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: organizeImage, style: .plain, target: self, action: #selector(cd(_:))), UIBarButtonItem(image: addImage, style: .plain, target: self, action: #selector(addTab))]
    }
    
    /// Saves tabs on the disk.
    var tabBookmarks: [Data] {
        var bookmarks = [Data]()
        for vc in viewControllers {
            if let term = vc as? LTTerminalViewController, let bookmarkData = term.bookmarkData {
                bookmarks.append(bookmarkData)
            }
        }
        return bookmarks
    }
    
    /// Interrupts the currently running command.
    @objc func interrupt() {
        (visibleViewController as? LTTerminalViewController)?.shell.killCommand()
    }
    
    /// Sends `EOF` to `stdin`.
    @objc func sendEOF() {
        (visibleViewController as? LTTerminalViewController)?.shell.sendEOF()
    }
    
    // MARK: - Tab view controller
    
    override var keyCommands: [UIKeyCommand]? {
        var commands = [
            UIKeyCommand(input: "T", modifierFlags: .command, action: #selector(addTab), discoverabilityTitle: "Open new tab"),
            UIKeyCommand(input: "W", modifierFlags: .command, action: #selector(closeCurrentTab), discoverabilityTitle: "Close tab"),
        ]
        
        if let shell = (visibleViewController as? LTTerminalViewController)?.shell, shell.isCommandRunning && !shell.isBuiltinRunning {
            
            commands.append(UIKeyCommand(input: "C", modifierFlags: .control, action: #selector(interrupt), discoverabilityTitle: "Interrupt"))
            commands.append(UIKeyCommand(input: "D", modifierFlags: .control, action: #selector(sendEOF), discoverabilityTitle: "Send End of File"))
        }
        
        return commands
    }
    
    required init(theme: TabViewTheme) {
        super.init(theme: theme)
        
        view.tintColor = LTTerminalViewController.Preferences().foregroundColor
        
        setupBarItems()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func closeTab(_ tab: UIViewController) {
        
        let terminal = tab as? LTTerminalViewController
        terminal?.shell.killCommand()
        
        if let session = terminal?.shell.io?.stdout {
            ios_closeSession(session)
        }
        
        super.closeTab(tab)
    }
}


