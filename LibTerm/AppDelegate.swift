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
        
        // The directory where scripts goes
        if let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("scripts"), !FileManager.default.fileExists(atPath: scriptsDirectory.path) {
            try? FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        
        // Colors
        putenv("TERM=ansi".cValue)
        
        window?.accessibilityIgnoresInvertColors = true
        
        if SettingsTableViewController.fontSize.integerValue == 0 {
            SettingsTableViewController.fontSize.integerValue = 14
        }
        
        // Request app review
        ReviewHelper.shared.launches += 1
        ReviewHelper.shared.requestReview()
        
        return true
    }

}

