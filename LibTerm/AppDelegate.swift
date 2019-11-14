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
import StoreKit
import ZipArchive
import Darwin

/// A Tab View theme that adapts to the system appearance.
@available(iOS 13.0, *) class DefaultTheme: TabViewTheme {
    
    var backgroundColor: UIColor {
        return .systemFill
    }
    
    var barTitleColor: UIColor {
        return .label
    }
    
    var barTintColor: UIColor {
        return .systemFill
    }
    
    var barBlurStyle: UIBlurEffect.Style {
        return .systemChromeMaterial
    }
    
    var separatorColor: UIColor {
        return .separator
    }
    
    var tabCloseButtonColor: UIColor {
        return TabViewThemeLight().tabCloseButtonColor
    }
    
    var tabCloseButtonBackgroundColor: UIColor {
        return TabViewThemeLight().tabCloseButtonBackgroundColor
    }
    
    var tabBackgroundDeselectedColor: UIColor {
        return TabViewThemeLight().tabBackgroundDeselectedColor
    }
    
    var tabTextColor: UIColor {
        return .label
    }
    
    var tabSelectedTextColor: UIColor {
        return .label
    }
    
    var statusBarStyle: UIStatusBarStyle {
        return .default
    }
}

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Installs programs installed from SeeLess.
    func movePrograms() {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libterm") else {
            return
        }
        
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
            }
            
            for file in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                if file.pathExtension == "ll" || file.pathExtension == "bc" {
                    let binURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("bin")
                    let destURL = binURL.appendingPathComponent(file.lastPathComponent)
                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.moveItem(at: file, to: destURL)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Application delegate
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if #available(iOS 13.0, *) {
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            let tabVC = TerminalTabViewController(theme: TabViewThemeLight())
            tabVC.viewControllers = [LTTerminalViewController.makeTerminal()]
            window?.rootViewController = tabVC
            window?.makeKeyAndVisible()
        }
        
        sideLoading = true
        
        // clang
        
        let usrURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("usr")
        
        if FileManager.default.fileExists(atPath: usrURL.path) {
            try? FileManager.default.removeItem(at: usrURL)
        }
        
        if let zipPath =  Bundle.main.path(forResource: "usr", ofType: "zip") {
            DispatchQueue.global().async {
                SSZipArchive.unzipFile(atPath: zipPath, toDestination: usrURL.deletingLastPathComponent().path, progressHandler: nil) { (_, success, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    if success {
                        //putenv("SDKPATH=\(Bundle.main.path(forResource: "iPhoneOS", ofType: "sdk") ?? "")".cValue)
                        putenv("C_INCLUDE_PATH=\(usrURL.appendingPathComponent("lib/clang/7.0.0/include").path):\(usrURL.appendingPathComponent("include").path)".cValue)
                    //putenv("OBJC_INCLUDE_PATH=\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
                        putenv("CPLUS_INCLUDE_PATH=\(usrURL.appendingPathComponent("include/c++/v1").path):\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include").path)".cValue)
                    //putenv("OBJCPLUS_INCLUDE_PATH=\(usrURL.appendingPathComponent("include/c++/v1")):\(usrURL.appendingPathComponent("lib/clang/7.0.0/include")):\(usrURL.appendingPathComponent("include"))".cValue)
                    }
                }
            }
        }
        
        // programs
        
        movePrograms()
        
        if let binURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libtermbin")?.appendingPathComponent("Documents") { // ~/Library/bin is now a symlink to a shared directory
            
            let localBinURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("bin")
            
            if !FileManager.default.fileExists(atPath: binURL.path) {
                try? FileManager.default.createDirectory(at: binURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            if (try? FileManager.default.destinationOfSymbolicLink(atPath: localBinURL.path)) != binURL.path {
                
                for file in (try? FileManager.default.contentsOfDirectory(at: localBinURL, includingPropertiesForKeys: nil, options: [])) ?? [] {
                    try? FileManager.default.moveItem(at: file, to: binURL.appendingPathComponent(file.lastPathComponent))
                }
                
                try? FileManager.default.removeItem(at: localBinURL)
                try? FileManager.default.createSymbolicLink(at: localBinURL, withDestinationURL: binURL)
            }
        }
        
        // ios_system
        
        initializeEnvironment()
        
        putenv("TERM=xterm-color".cValue)
                
        replaceCommand("pbcopy", "pbcopy_main", true)
        replaceCommand("pbpaste", "pbpaste_main", true)
        replaceCommand("id", "id_main", true)
        
        putenv("SHAREDDIR=\(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libterm")?.path ?? "")".cValue)
        
        // Python
        putenv("PYTHONOPTIMIZE=".cValue)
        putenv("PYTHONDONTWRITEBYTECODE=1".cValue)
        
        // cacert.pem
        let cacertNewURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("cacert.pem")
        if let cacertURL = Bundle.main.url(forResource: "cacert", withExtension: "pem"), !FileManager.default.fileExists(atPath: cacertNewURL.path) {
            try? FileManager.default.copyItem(at: cacertURL, to: cacertNewURL)
        }
        
        if let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("bin"), let oldScriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("scripts"), FileManager.default.fileExists(atPath: oldScriptsDirectory.path), !FileManager.default.fileExists(atPath: scriptsDirectory.path) {
            try? FileManager.default.moveItem(at: oldScriptsDirectory, to: scriptsDirectory)
        }
        
        // The directory where scripts goes
        if let scriptsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first?.appendingPathComponent("bin"), !FileManager.default.fileExists(atPath: scriptsDirectory.path) {
            try? FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: false, attributes: nil)
        }
                
        window?.accessibilityIgnoresInvertColors = true
        
        if SettingsTableViewController.fontSize.integerValue == 0 {
            SettingsTableViewController.fontSize.integerValue = 14
        }
        
        // Request app review
        ReviewHelper.shared.launches += 1
        ReviewHelper.shared.requestReview()
        
        return true
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}

