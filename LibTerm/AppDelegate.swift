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
import SwiftyStoreKit

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TerminalTabViewController(theme: TabViewThemeDark())
        window?.makeKeyAndVisible()

        #if DEBUG
        Python3Locker.originalApplicationVersion.stringValue = "4.0"
        #else
        if Python3Locker.originalApplicationVersion.stringValue == nil {
            receiptValidation()
        }
        #endif
        
        initializeEnvironment()
        
        replaceCommand("pbcopy", "pbcopy", true)
        replaceCommand("pbpaste", "pbpaste", true)
        
        // Python
        putenv("PYTHONHOME=\(Bundle.main.bundlePath)".cValue)
        putenv("PYTHONOPTIMIZE=".cValue)
        putenv("PYTHONDONTWRITEBYTECODE=1".cValue)
        
        // cacert.pem
        let cacertNewURL = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("cacert.pem")
        if let cacertURL = Bundle.main.url(forResource: "cacert", withExtension: "pem"), !FileManager.default.fileExists(atPath: cacertNewURL.path) {
            try? FileManager.default.copyItem(at: cacertURL, to: cacertNewURL)
        }
        
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
        
        // In app purchases
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    
                    // Unlock content
                    
                    if purchase.productId == SettingsTableViewController.python37ProductID {
                        Python3Locker.isPython3Purchased.boolValue = true
                    }
                    
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
        
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            if product.productIdentifier == SettingsTableViewController.python37ProductID {
                
                if (Python3Locker.originalApplicationVersion.stringValue ?? "1.0") < "4.0" {
                    
                    let alert = UIAlertController(title: "Product purchased", message: "As you downloaded LibTerm before 4.0, you have Python 3.7 for free.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                    
                    return false
                }
                
                return true
            } else {
                return false
            }
        }
        
        // Request app review
        ReviewHelper.shared.launches += 1
        ReviewHelper.shared.requestReview()
        
        return true
    }

}

