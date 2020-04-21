//
//  edit.swift
//  LibTerm
//
//  Created by Adrian Labbe on 12/12/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import InputAssistant
import Highlightr

fileprivate class EditTextViewController: UIViewController, InputAssistantViewDelegate, InputAssistantViewDataSource {
    
    var file: URL!
    
    var semaphore: DispatchSemaphore?
    
    let inputAssistant = InputAssistantView()
    
    init(file: URL) {
        super.init(nibName: nil, bundle: nil)
        self.file = file
    }
    
    // MARK: - View controller
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: "ir-black")
        
        let languages = NSDictionary(contentsOf: Bundle.main.bundleURL.appendingPathComponent("langs.plist"))! as! [String:[String]] // List of languages associated by file extensions
        
        if let languagesForFile = languages[file.pathExtension.lowercased()] {
            if languagesForFile.count > 0 {
                storage.language = languagesForFile[0]
            }
        }
        
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        layoutManager.addTextContainer(textContainer)
        
        let textView = UITextView(frame: .zero, textContainer: textContainer)
        
        textView.font = UIFont(name: "Courier", size: CGFloat(SettingsTableViewController.fontSize.floatValue))
        textView.backgroundColor = .black
        textView.textColor = .white
        
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.keyboardAppearance = .dark
        
        view = textView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        inputAssistant.dataSource = self
        inputAssistant.delegate = self
        inputAssistant.attach(to: (view as! UITextView))
        
        title = file.lastPathComponent
    }
    
    // MARK: - Suggestions
    
    enum State {
        case editing
        case saving
    }
    
    var state = State.editing {
        didSet {
            inputAssistant.reloadData()
        }
    }
    
    // MARK: - Input assistant view data source
    
    func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        if state == .editing {
            return 1
        } else if state == .saving {
            return 2
        } else {
            return 0
        }
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        if state == .editing {
            return "Close"
        } else if state == .saving {
            let suggestions = ["Save", "Don't Save"]
            return suggestions[index]
        } else {
            return ""
        }
    }
    
    // MARK: - Input assistant view delegate
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        
        if state == .editing {
            state = .saving
        } else {
            if index == 0 { // Save
                do {
                    try (view as? UITextView)?.text.write(to: file, atomically: true, encoding: .utf8)
                    dismiss(animated: false) {
                        self.semaphore?.signal()
                    }
                } catch {
                    let alert = UIAlertController(title: "Error saving file!", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(alert, animated: true, completion: nil)
                }
            } else { // Don't save
                dismiss(animated: true) {
                    self.semaphore?.signal()
                }
            }
        }
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        guard let textView = view as? UITextView else {
            return
        }
        
        let d = notification.userInfo!
        var r = d[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        r = textView.convert(r, from:nil)
        textView.contentInset.bottom = r.size.height
        textView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        guard let textView = view as? UITextView else {
            return
        }
        
        textView.contentInset = .zero
        textView.scrollIndicatorInsets = .zero
    }
}

/// The `edit` command.
func editMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    var args = argv
    args.removeFirst()
    
    if args.count == 0 {
        fputs("Usage:\n\n  \(argv[0]) [FILE]...\n", io.stderr)
        return 1
    }
    
    for arg in args {
        let url = URL(fileURLWithPath: arg, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        
        do {
            let str: String
            
            if FileManager.default.fileExists(atPath: url.path) {
                str = try String(contentsOf: url)
            } else {
                str = ""
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                let editor = EditTextViewController(file: url)
                editor.loadViewIfNeeded()
                (editor.view as? UITextView)?.text = str
                
                editor.semaphore = semaphore
                
                let navVC = UINavigationController(rootViewController: editor)
                navVC.navigationBar.barStyle = .black
                navVC.modalPresentationStyle = .fullScreen
                
                io.terminal?.present(navVC, animated: false, completion: {
                    editor.view.becomeFirstResponder()
                })
            }
            
            semaphore.wait()
        } catch {
            fputs("\(argv[0]): \(arg): \(error.localizedDescription)\n", io.stderr)
            return 1
        }
    }
    
    return 0
}
