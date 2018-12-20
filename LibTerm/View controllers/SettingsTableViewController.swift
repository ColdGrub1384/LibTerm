//
//  SettingsTableViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/16/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ObjectUserDefaults
import SafariServices
import StoreKit
import SwiftyStoreKit

/// A View controller with info about the app and some settings.
class SettingsTableViewController: UITableViewController, SKStoreProductViewControllerDelegate {
    
    /// The object representing the terminal font size.
    static let fontSize = ObjectUserDefaults.standard.item(forKey: "fontSize")
    
    /// The object representig the terminal caret style.
    static let caretStyle = ObjectUserDefaults.standard.item(forKey: "caretStyle")
    
    private struct ProjectsIndexPaths {
        private init() {}
        
        static let ios_system = IndexPath(row: 0, section: 2)
        static let openTerm = IndexPath(row: 1, section: 2)
        static let inputAssistant = IndexPath(row: 2, section: 2)
        static let tabView = IndexPath(row: 3, section: 2)
        static let highlightr = IndexPath(row: 4, section: 2)
        static let objectUserDefaults = IndexPath(row: 5, section: 2)
        
        static let libTerm = IndexPath(row: 0, section: 3)
        
        static let pisth = IndexPath(row: 0, section: 4)
        static let pyto = IndexPath(row: 1, section: 4)
        static let luade = IndexPath(row: 2, section: 4)
        static let edidown = IndexPath(row: 3, section: 4)
    }
    
    /// Closes this View controller.
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: {
            if let term = (UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController)?.visibleViewController as? LTTerminalViewController {
                term.terminalTextView.attributedText = NSAttributedString(string: "")
                term.tprint(term.attributedConsole.string)
            }
        })
    }
    
    /// The label containing the current font size.
    @IBOutlet weak var fontSizeLabel: UILabel!
    
    /// The stepper for changing the font size.
    @IBOutlet weak var fontSizeStepper: UIStepper!
    
    /// The segmented control for changing 
    @IBOutlet weak var caretStyleSegmentedControl: UISegmentedControl!
    
    /// Called for changing the font size.
    @IBAction func fontSizeChanged(_ sender: UIStepper) {
        SettingsTableViewController.fontSize.doubleValue = sender.value
        fontSizeLabel.text = "\(sender.value)"
    }
    
    /// Called for changing the caret style.
    @IBAction func caretStyleChangedChanged(_ sender: UISegmentedControl) {
        SettingsTableViewController.caretStyle.integerValue = sender.selectedSegmentIndex
    }
    
    // MARK: - In app purchases
    
    /// The ID of the Python 3.7 In App Purchase.
    static let python37ProductID = "ch.marcela.ada.LibTerm.python37"
    
    private struct InAppPurchasesIndexPaths {
        private init() {}
        
        static let python37 = IndexPath(row: 0, section: 0)
        
        static let restore = IndexPath(row: 1, section: 0)
    }
    
    // MARK: - Table view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        caretStyleSegmentedControl.selectedSegmentIndex = SettingsTableViewController.caretStyle.integerValue
        fontSizeStepper.value = SettingsTableViewController.fontSize.doubleValue
        fontSizeLabel.text = "\(SettingsTableViewController.fontSize.doubleValue)"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0, (Python3Locker.originalApplicationVersion.stringValue ?? "4.0" < "4.0") {
            return 0
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if indexPath == InAppPurchasesIndexPaths.python37 {
            for view in cell.contentView.subviews {
                (view as? UIButton)?.isEnabled = !Python3Locker.isPython3Purchased.boolValue
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // MARK: - In App Purchases
        
        if indexPath == InAppPurchasesIndexPaths.python37 {
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            guard !Python3Locker.isPython3Purchased.boolValue else {
                return
            }
            
            // Purchase Python 3.7
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            SwiftyStoreKit.purchaseProduct(SettingsTableViewController.python37ProductID) { (result) in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                var title: String
                var message: String
                
                switch result {
                case .success(let purchase):
                    title = "Purchase succeed!"
                    message = "Thank you!\nYou can now use Python 3.7 by typing 'python' command."
                    Python3Locker.isPython3Purchased.boolValue = true
                    tableView.reloadData()
                case .error(let error):
                    switch error.code {
                    case .unknown:
                        title = "Unknown error"
                        message = ""
                    case .clientInvalid:
                        title = "Purchase failed"
                        message = "Not allowed to make the payment"
                    case .paymentCancelled: return
                    case .paymentInvalid:
                        title = "Product not found"
                        message = "This should not happen, please let me know this bug."
                    case .paymentNotAllowed:
                        title = "Purchase failed"
                        message = "The device is not allowed to make the payment"
                    case .storeProductNotAvailable:
                        title = "Purchase failed"
                        message = "The product is not available in the current storefront"
                    case .cloudServicePermissionDenied:
                        title = "Purchase failed"
                        message = "Access to cloud service information is not allowed"
                    case .cloudServiceNetworkConnectionFailed:
                        title = "Purchase failed"
                        message = "Could not connect to the network"
                    case .cloudServiceRevoked:
                        title = "Purchase failed"
                        message = "User has revoked permission to use this cloud service"
                    default:
                        title = "Purchase failed"
                        message = (error as NSError).localizedDescription
                    }
                }
                
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
        } else if indexPath == InAppPurchasesIndexPaths.restore {
            tableView.deselectRow(at: indexPath, animated: true)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            SwiftyStoreKit.restorePurchases { (results) in
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                for purchase in results.restoredPurchases {
                    if purchase.productId == SettingsTableViewController.python37ProductID {
                        Python3Locker.isPython3Purchased.boolValue = true
                    }
                }
                
                tableView.reloadData()
            }
        }
        
        // MARK: - Projects
        
        func present(appWithID id: String) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let appStore = SKStoreProductViewController()
            appStore.delegate = self
            appStore.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier:id], completionBlock: nil)
            self.present(appStore, animated: true, completion: nil)
        }
        
        var projectPath: String?
        switch indexPath {
        case ProjectsIndexPaths.ios_system:
            projectPath = "holzschu/ios_system"
        case ProjectsIndexPaths.openTerm:
            projectPath = "louisdh/openterm"
        case ProjectsIndexPaths.inputAssistant:
            projectPath = "IMcD23/InputAssistant"
        case ProjectsIndexPaths.tabView:
            projectPath = "IMcD23/TabView"
        case ProjectsIndexPaths.highlightr:
            projectPath = "raspu/Highlightr"
        case ProjectsIndexPaths.objectUserDefaults:
            projectPath = "ColdGrub1384/ObjectUserDefaults"
        case ProjectsIndexPaths.libTerm:
            projectPath = "ColdGrub1384/LibTerm"
        case ProjectsIndexPaths.pisth:
            present(appWithID: "1331070425")
        case ProjectsIndexPaths.pyto:
            present(appWithID: "1436650069")
        case ProjectsIndexPaths.luade:
            present(appWithID: "1444956026")
        case ProjectsIndexPaths.edidown:
            present(appWithID: "1439139639")
        default:
            break
        }
        if let path = projectPath, let url = URL(string: "https://github.com/\(path)") {
            self.present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }
    
    // MARK: - Store product view controller delegate
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
