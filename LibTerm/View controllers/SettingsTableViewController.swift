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

/// A View controller with info about the app and some settings.
class SettingsTableViewController: UITableViewController {
    
    /// The object representing the terminal font size.
    static let fontSize = ObjectUserDefaults.standard.item(forKey: "fontSize")
    
    /// The object representig the terminal caret style.
    static let caretStyle = ObjectUserDefaults.standard.item(forKey: "caretStyle")
    
    private struct ProjectsIndexPaths {
        private init() {}
        
        static let ios_system = IndexPath(row: 0, section: 1)
        static let openTerm = IndexPath(row: 1, section: 1)
        static let inputAssistant = IndexPath(row: 2, section: 1)
        static let tabView = IndexPath(row: 3, section: 1)
        static let objectUserDefaults = IndexPath(row: 4, section: 1)
        
        static let libTerm = IndexPath(row: 0, section: 2)
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
        SettingsTableViewController.fontSize.doubleValue += 1
        fontSizeLabel.text = "\(sender.value)"
    }
    
    /// Called for changing the caret style.
    @IBAction func caretStyleChangedChanged(_ sender: UISegmentedControl) {
        SettingsTableViewController.caretStyle.integerValue = sender.selectedSegmentIndex
    }
    
    // MARK: - Table view controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        caretStyleSegmentedControl.selectedSegmentIndex = SettingsTableViewController.caretStyle.integerValue
        fontSizeStepper.value = SettingsTableViewController.fontSize.doubleValue
        fontSizeLabel.text = "\(SettingsTableViewController.fontSize.doubleValue)"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        case ProjectsIndexPaths.objectUserDefaults:
            projectPath = "ColdGrub1384/ObjectUserDefaults"
        case ProjectsIndexPaths.libTerm:
            projectPath = "ColdGrub1384/LibTerm"
        default:
            break
        }
        if let path = projectPath, let url = URL(string: "https://github.com/\(path)") {
            present(SFSafariViewController(url: url), animated: true, completion: nil)
        }
    }
}
