//
//  AppDelegate.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Python
        putenv("PYTHONHOME=\(Bundle.main.bundlePath)".cValue)
        putenv("PYTHONPATH=\(Bundle.main.bundlePath)/site-packages".cValue)
        putenv("PYTHONOPTIMIZE=".cValue)
        putenv("PYTHONDONTWRITEBYTECODE=1".cValue)
        
        // Home
        let docs = ("~/Documents" as NSString).expandingTildeInPath
        putenv("SSH_HOME=\(docs)".cValue)
        putenv("DIG_HOME=\(docs)".cValue)
        putenv("CURL_HOME=\(docs)".cValue)
        
        window?.accessibilityIgnoresInvertColors = true
        
        return true
    }

}

