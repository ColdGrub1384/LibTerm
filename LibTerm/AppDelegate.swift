//
//  AppDelegate.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import TabView
import ios_system
import ObjectUserDefaults

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TerminalTabViewController(theme: TabViewThemeDark())
        window?.makeKeyAndVisible()
        
        sideLoading = true
        initializeEnvironment()
        
        // Python
        putenv("PYTHONHOME=\(Bundle.main.bundlePath)".cValue)
        putenv("PYTHONPATH=\(Bundle.main.bundlePath)/site-packages".cValue)
        putenv("PYTHONOPTIMIZE=".cValue)
        putenv("PYTHONDONTWRITEBYTECODE=1".cValue)
        
        // Colors
        putenv("TERM=ansi".cValue)
        
        window?.accessibilityIgnoresInvertColors = true
        
        if SettingsTableViewController.fontSize.integerValue == 0 {
            SettingsTableViewController.fontSize.integerValue = 14
        }
        
        return true
    }

}

