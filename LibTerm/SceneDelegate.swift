//
//  SceneDelegate.swift
//  LibTerm
//
//  Created by Adrian Labbé on 10-08-19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import UIKit
import TabView

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        window = UIWindow(frame: (scene as? UIWindowScene)?.coordinateSpace.bounds ?? UIScreen.main.bounds)
        let tabVC = TerminalTabViewController(theme: DefaultTheme())
        if let bookmarks = session.stateRestorationActivity?.userInfo?["tabs"] as? [Data],
            !bookmarks.isEmpty,
            let contents = session.stateRestorationActivity?.userInfo?["contents"] as? [Data],
            bookmarks.count == contents.count,
            let history = session.stateRestorationActivity?.userInfo?["history"] as? [[String]],
            bookmarks.count == contents.count {
            
            var terminals = [LTTerminalViewController]()
            
            for (i, bookmark) in bookmarks.enumerated() {
                var isStale = false
                
                if let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) {
                 
                    _ = url.startAccessingSecurityScopedResource()
                    
                    let term = LTTerminalViewController.makeTerminal()
                    term.restoredSession = true
                    if let attrString = (try? NSAttributedString(data: contents[i], options: [.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil)) {
                        term.attributedConsole = NSMutableAttributedString(attributedString: attrString)
                    }
                    term.loadViewIfNeeded()
                    term.shell.history = history[i]
                    term.url = url
                    term.title = url.lastPathComponent
                    terminals.append(term)
                }
            }
            
            if terminals.isEmpty {
                terminals = [LTTerminalViewController.makeTerminal()]
            }
            
            tabVC.viewControllers = terminals
            
            if let i = session.stateRestorationActivity?.userInfo?["selected"] as? Int, terminals.count > i {
                tabVC.visibleViewController = terminals[i]
            }
            
        } else {
            let terminal = ((connectionOptions.userActivities.first?.viewController as? LTTerminalViewController) ?? LTTerminalViewController.makeTerminal())
            for window in UIApplication.shared.windows {
                if let tabVC = window.rootViewController as? TerminalTabViewController {
                    if tabVC.viewControllers.contains(terminal) {
                        tabVC.closeTab(terminal)
                        break
                    }
                }
            }
            tabVC.viewControllers = [terminal]
        }
        window?.rootViewController = tabVC
        window?.windowScene = scene as? UIWindowScene
        window?.makeKeyAndVisible()
    }
    
    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.movePrograms()
    }
    
    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.movePrograms()
    }
    
    @available(iOS 13.0, *)
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        if let tabVC = (scene as? UIWindowScene)?.windows.first?.rootViewController as? TerminalTabViewController {
            let userActivity = NSUserActivity(activityType: "Tabs")
            
            var contents = [Data]()
            var history = [[String]]()
            
            for terminal in tabVC.viewControllers {
                if let text = (terminal as? LTTerminalViewController)?.terminalTextView.attributedText, let data = (try? text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])) {
                    contents.append(data)
                }
                
                if let _history = (terminal as? LTTerminalViewController)?.shell.history {
                    history.append(_history)
                }
            }
            
            userActivity.addUserInfoEntries(from: ["tabs":tabVC.tabBookmarks, "contents":contents, "history":history, "selected":(tabVC.selectedIndex ?? nil) as Any])
            return userActivity
        } else {
            return nil
        }
    }
}
