//
//  ViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import InputAssistant
#if !targetEnvironment(simulator)
import ios_system
#endif
#if !FRAMEWORK
import ObjectUserDefaults
#endif

/// The terminal interacting with the shell. Only one terminal should be visible at a time.
public class LTTerminalViewController: UIViewController, UITextViewDelegate, InputAssistantViewDelegate, InputAssistantViewDataSource, UIDocumentPickerDelegate {
    
    /// A structure containing terminal's UI preferences.
    public struct Preferences {
        
        fileprivate var foregroundColor_: UIColor?
        fileprivate var backgroundColor_: UIColor?
        fileprivate var fontSize_: Double?
        fileprivate var caretStyle_ = 0
        
        /// Caret styles used in the terminal.
        public enum CaretStyle: Int {
            
            /// The default text view's caret style.
            case verticalBar = 0
            
            /// A block.
            case block = 1
            
            /// An horizontal bar.
            case underline = 2
        }
        
        /// Terminal's keyboard appearance.
        public var keyboardAppearance = UIKeyboardAppearance.dark
        
        /// Terminal's foreground color.
        public var foregroundColor: UIColor {
            set {
                foregroundColor_ = newValue
            }
            get {
                if #available(iOS 11.0, *) {
                    return foregroundColor_ ?? UIColor(named: "Foreground Color", in: Bundle(for: LTTerminalViewController.self), compatibleWith: nil)!
                } else {
                    return foregroundColor_ ?? .green
                }
            }
        }
        
        /// Terminal's background color.
        public var backgroundColor: UIColor {
            set {
                backgroundColor_ = newValue
            }
            get {
                if #available(iOS 11.0, *) {
                    return backgroundColor_ ?? UIColor(named: "Background Color", in: Bundle(for: LTTerminalViewController.self), compatibleWith: nil)!
                } else {
                    return backgroundColor_ ?? .black
                }
            }
        }
        
        /// The terminal's font size.
        public var fontSize: Double {
            get {
                #if FRAMEWORK
                return fontSize_ ?? 14
                #else
                let fontSize__ = SettingsTableViewController.fontSize.doubleValue
                if fontSize__ == 0 {
                    return fontSize_ ?? 14
                } else {
                    return fontSize__
                }
                #endif
            }
            set {
                #if FRAMEWORK
                fontSize_ = newValue
                #else
                SettingsTableViewController.fontSize.doubleValue = newValue
                #endif
            }
        }
        
        /// The terminal's caret style.
        public var caretStyle: CaretStyle {
            get {
                #if FRAMEWORK
                return CaretStyle(rawValue: caretStyle_) ?? CaretStyle.verticalBar
                #else
                return CaretStyle(rawValue: SettingsTableViewController.caretStyle.integerValue) ?? LTTerminalViewController.Preferences.CaretStyle(rawValue: 0)!
                #endif
            }
            set {
                #if FRAMEWORK
                caretStyle_ = newValue.rawValue
                #else
                SettingsTableViewController.caretStyle.integerValue = newValue.rawValue
                #endif
            }
        }
        
        /// The nav bar's style.
        public var barStyle = UIBarStyle.black
        
        public init() { }
    }
    
    static private var visible_: LTTerminalViewController?
    
    /// The currently visible terminal.
    static public var visible: LTTerminalViewController? {
        return visible_
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Initialize with given preferences.
    public class func makeTerminal(preferences: Preferences = Preferences(), shell: LibShell = LibShell()) -> LTTerminalViewController {
        let term = UIStoryboard(name: "Terminal", bundle: Bundle(for: LTTerminalViewController.self)).instantiateInitialViewController() as! LTTerminalViewController
        term.preferences = preferences
        term.shell = shell
        return term
    }
    
    /// Terminal's preferences.
    public private(set) var preferences = Preferences()
    
    /// The Text view displaying content.
    @IBOutlet weak public var terminalTextView: LTTerminalTextView!
    
    /// The permanent console without the actual user input.
    var attributedConsole = NSMutableAttributedString()
    
    /// The actual user input.
    var prompt = "" {
        didSet {
            updateSuggestions()
        }
    }
    
    /// `true` if the shell is asking for input.
    var isAskingForInput = false
    
    /// `true` if a command is asking for input.
    var isWrittingToStdin = false
    
    /// The shell for running command.
    public private(set) var shell = LibShell()
    
    /// The thread running the shell.
    var thread = DispatchQueue.global(qos: .userInteractive)
    
    /// The view for autocompletion.
    let assistant = InputAssistantView()
    
    /// Asks the user for a command.
    ///
    /// - Parameters:
    ///     - prompt: The prompt.
    func input(prompt: String) {
        title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        isWrittingToStdin = false
        isAskingForInput = false
        tprint(prompt)
        textViewDidChange(terminalTextView)
        isAskingForInput = true
        updateSuggestions()
    }
    
    /// Prints the given text.
    ///
    /// - Parameters:
    ///     - text: Text to print.
    public func tprint(_ text: String) {
                
        let newAttrs = NSMutableAttributedString(attributedString: terminalTextView.attributedText ?? NSAttributedString())
        newAttrs.append(NSAttributedString(string: text, attributes: [.font : UIFont(name: "Menlo", size: CGFloat(preferences.fontSize)) ?? UIFont.systemFont(ofSize: CGFloat(preferences.fontSize)), .foregroundColor: preferences.foregroundColor]))
        terminalTextView.attributedText = newAttrs
    }
    
    /// Select a new working directory.
    public func cd() {
        let vc = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        vc.delegate = self
        if #available(iOS 11.0, *) {
            vc.allowsMultipleSelection = true
        }
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Private values for theming inside Pisth or other apps
    
    private var navigationController_: UINavigationController?
    private var defaultBarStyle = UIBarStyle.default
    
    // MARK: - View controller
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        view.tintColor = preferences.foregroundColor
        view.backgroundColor = preferences.backgroundColor
        
        LTTerminalViewController.visible_ = self
        shell.io = LTIO(terminal: self)
        shell.input()
        
        assistant.delegate = self
        assistant.dataSource = self
        assistant.trailingActions = [InputAssistantAction(image: LTTerminalViewController.downArrow, target: terminalTextView, action: #selector(terminalTextView.resignFirstResponder))]
        assistant.attach(to: terminalTextView)
        
        terminalTextView.keyboardAppearance = preferences.keyboardAppearance
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let io = shell.io {
            #if !targetEnvironment(simulator)
            title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
            ios_switchSession(io.stdout)
            ios_setStreams(io.stdin, io.stdout, io.stderr)
            #endif
        }
        
        LTTerminalViewController.visible_ = self
        navigationController_ = navigationController
        defaultBarStyle = navigationController?.navigationBar.barStyle ?? .default
        navigationController?.navigationBar.barStyle = preferences.barStyle
        navigationController?.setNeedsStatusBarAppearanceUpdate()
        
        terminalTextView.resignFirstResponder()
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            self.terminalTextView.becomeFirstResponder()
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        LTTerminalViewController.visible_ = nil
        navigationController_?.navigationBar.barStyle = defaultBarStyle
        navigationController_?.setNeedsStatusBarAppearanceUpdate()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        terminalTextView.becomeFirstResponder()
    }
    
    override public func viewDidLayoutSubviews() {
        
        var columns: Int {
            
            guard let font = terminalTextView.font else {
                assertionFailure("Expected font")
                return 0
            }
            
            // TODO: check if the bounds includes the safe area (on iPhone X)
            let viewWidth = terminalTextView.bounds.width
            
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charWidth = dummyAtributedString.size().width
            
            // Assumes the font is monospaced
            return Int(viewWidth / charWidth)
        }
        
        var rows: Int {
            
            guard let font = terminalTextView.font else {
                assertionFailure("Expected font")
                return 0
            }
            
            // TODO: check if the bounds includes the safe area (on iPhone X)
            let viewHeight = terminalTextView.bounds.height
            
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charHeight = dummyAtributedString.size().height
            
            // Assumes the font is monospaced
            return Int(viewHeight / charHeight)
        }
        
        putenv("COLUMNS=\(columns)".cValue)
        putenv("ROWS=\(rows)".cValue)
    }
    
    // MARK: - Keyboard

    @objc func keyboardWillShow(_ notification: Notification) {
        let d = notification.userInfo!
        var r = d[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        r = terminalTextView.convert(r, from:nil)
        terminalTextView.contentInset.bottom = r.size.height
        terminalTextView.scrollIndicatorInsets.bottom = r.size.height
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        terminalTextView.contentInset = .zero
        terminalTextView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Text view delegate
    
    public func textViewDidChange(_ textView: UITextView) {
        if !isAskingForInput && !isWrittingToStdin, let attrs = textView.attributedText {
            attributedConsole = NSMutableAttributedString(attributedString: attrs)
        }
        isWrittingToStdin = false
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let location:Int = textView.offset(from: textView.beginningOfDocument, to: textView.endOfDocument)
        let length:Int = textView.offset(from: textView.endOfDocument, to: textView.endOfDocument)
        let end =  NSMakeRange(location, length)
        
        if end != range && !(text == "" && range.length == 1 && range.location+1 == end.location) {
            // Only allow inserting text from the end
            return false
        }
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).count >= attributedConsole.string.count {
            
            isWrittingToStdin = !isAskingForInput
            
            self.prompt += text
            
            if text == "\n" {
                
                if !isAskingForInput, let data = self.prompt.data(using: .utf8) {
                    tprint("\n")
                    shell.io?.inputPipe.fileHandleForWriting.write(data)
                    self.prompt = ""
                    return false
                }
                
                self.prompt = String(self.prompt.dropLast())
                tprint("\n")
                textViewDidChange(textView)
                isAskingForInput = false
                isWrittingToStdin = false
                
                let prompt = self.prompt
                self.prompt = ""
                
                defer {
                    thread = DispatchQueue.global(qos: .utility)
                    thread.async {
                        self.shell.run(command: prompt)
                        DispatchQueue.main.async {
                            _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                                self.shell.input()
                            })
                        }
                        Thread.current.cancel()
                    }
                }
                
                return false
            } else if text == "" && range.length == 1 {
                prompt = String(prompt.dropLast())
            }
            
            return true
        }
        
        return false
    }
    
    // MARK: - Input assistant
    
    private static var downArrow: UIImage {
        return UIGraphicsImageRenderer(size: .init(width: 24, height: 24)).image(actions: { context in
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 1, y: 7))
            path.addLine(to: CGPoint(x: 11, y: 17))
            path.addLine(to: CGPoint(x: 22, y: 7))
            
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            context.cgContext.addPath(path.cgPath)
            
        }).withRenderingMode(.alwaysOriginal)
    }
    
    private var currentCommand: LTCommandHelp? {
        for command in LTHelp {
            if command.commandName == prompt.components(separatedBy: " ")[0] {
                return command
            }
        }
        return nil
    }
    
    private var completionType: LTCommandHelp.CompletionType {
        
        guard !shell.isCommandRunning else {
            return .running
        }
        
        if let command = currentCommand, prompt.hasSuffix(" ") {
            return command.commandInput
        } else if prompt.isEmpty {
            return .history
        } else {
            return .command
        }
    }
    
    private var commands_: [String] {
        
        guard completionType != .running else {
            return ["Stop"]
        }
        
        var suggestions: [String] {
            let flags = currentCommand?.flags ?? []
            if completionType == .none {
                return flags
            } else if completionType == .file, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                return [".", "../"]+files+flags
            } else if completionType == .directory, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                var dirs = [".", "../"]
                for file in files {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) && isDir.boolValue {
                        dirs.append(file)
                    }
                }
                return dirs+flags
            } else if completionType == .history {
                var commands_ = shell.history.reversed() as [String]
                for command in LTHelp {
                    if !commands_.contains(command.commandName) {
                        commands_.append(command.commandName)
                    }
                }
                return commands_
            } else {
                var commands_ = shell.history.reversed() as [String]
                var help = LTHelp
                for file in (try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("scripts").path)) ?? [] {
                    if file.lowercased().hasSuffix(".py") {
                        help.append(LTCommandHelp(commandName: (file as NSString).deletingPathExtension, commandInput: .none))
                    }
                }
                for command in help {
                    if command.commandName.contains(prompt.components(separatedBy: " ")[0].lowercased()) && !commands_.contains(command.commandName) {
                        commands_.append(command.commandName)
                    }
                }
                var i = 0
                var newCommands = commands_
                for command in commands_ {
                    if !command.contains(prompt) {
                        newCommands.remove(at: i)
                    } else {
                        i += 1
                    }
                }
                return newCommands
            }
        }

        var suggestions_ = [String]()
        for suggestion in suggestions {
            if !suggestions_.contains(suggestion) {
                suggestions_.append(suggestion)
            }
        }
        
        return suggestions_
    }
    
    /// Updates suggestions
    public func updateSuggestions() {
        commands = commands_
    }
    
    private var commands = [String]() {
        didSet {
            DispatchQueue.main.async {
                self.assistant.reloadData()
            }
        }
    }
    
    // MARK: - Input assistant view delegate
    
    public func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        
        if completionType == .running {
            if let tabVC = UIApplication.shared.keyWindow?.rootViewController as? TerminalTabViewController { // Close all tabs that will not be working after closing a program
                for tab in tabVC.viewControllers {
                    if tab !== self {
                        tabVC.closeTab(tab)
                    }
                }
                if tabVC.navigationItem.rightBarButtonItems?.count == 2 {
                    tabVC.navigationItem.rightBarButtonItems?.remove(at: 1)
                }
            }
            return shell.killCommand()
        } else if completionType != .command && completionType != .history {
            prompt += commands_[index]+" "
        } else {
            prompt = commands_[index]+" "
        }
        terminalTextView.attributedText = attributedConsole
        tprint(prompt)
    }
    
    // MARK: - Input assistant view data source
    
    public func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    public func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        
        return commands_[index]
    }
    
    public func numberOfSuggestionsInInputAssistantView() -> Int {
        if isAskingForInput || shell.isCommandRunning {
            return commands_.count
        } else {
            return 0
        }
    }
    
    // MARK: - Document picker delegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count != 1 {
            let alert = UIAlertController(title: "Select a directory", message: "Please select 1 new working directory. \(urls.count) directories were picked.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.present(controller, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        if urls[0].startAccessingSecurityScopedResource() {
            #if !targetEnvironment(simulator)
            ios_system("cd '\(urls[0].path)'")
            #endif
            title = urls[0].lastPathComponent
        } else {
            tprint("Error opening \(urls[0].lastPathComponent).\n")
            shell.input()
        }
    }
}

