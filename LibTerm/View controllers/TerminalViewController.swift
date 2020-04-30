//
//  ViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import InputAssistant
import ios_system
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
        public var keyboardAppearance: UIKeyboardAppearance = .default
        
        /// Terminal's foreground color.
        public var foregroundColor: UIColor {
            set {
                foregroundColor_ = newValue
            }
            get {
                if #available(iOS 13.0, *) {
                    return foregroundColor_ ?? (SettingsTableViewController.greenText.boolValue ? UIColor(named: "Green")! : UIColor.label)
                } else {
                    return foregroundColor_ ?? (SettingsTableViewController.greenText.boolValue ? UIColor(named: "Green")! : UIColor.black)
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
        shell.io = term.shell.io
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
    public var thread = DispatchQueue.global(qos: .userInteractive)
    
    /// The view for autocompletion.
    var assistant = InputAssistantView()
    
    /// Asks the user for a command.
    ///
    /// - Parameters:
    ///     - prompt: The prompt.
    func input(prompt: String) {
    
        if view.window != nil {
            title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        }
    
        isWrittingToStdin = false
        isAskingForInput = false
        self.prompt = ""
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
    
    /// The current directory bookmark data for this terminal session for being restored at launch.
    var bookmarkData: Data?
    
    /// The URL to navigate at View did appear.
    var url: URL?
    
    /// Set to `true` if the session was restored.
    var restoredSession = false
    
    // MARK: - Private values for theming inside Pisth or other apps
    
    private var navigationController_: UINavigationController?
    private var defaultBarStyle = UIBarStyle.default
    
    /// A custom title for the terminal.
    public var customTitle: String?
    
    /// Sets "COLUMNS" and "ROWS" environment variables.
    func updateSize() {
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
            return Int((viewWidth / charWidth).rounded(.down))
        }
        
        var rows: Int {
            
            guard let font = terminalTextView.font else {
                assertionFailure("Expected font")
                return 0
            }
            
            // TODO: check if the bounds includes the safe area (on iPhone X)
            let viewHeight = terminalTextView.bounds.height-terminalTextView.contentInset.bottom
            
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charHeight = dummyAtributedString.size().height
            
            // Assumes the font is monospaced
            return Int((viewHeight / charHeight).rounded(.down))
        }
        
        setenv("COLUMNS", "\(columns)", 1)
        setenv("LINES", "\(rows)", 1)
        
        kill(getpid(), SIGWINCH)
    }
    
    private static var unarchivedUsr = false
    
    // MARK: - View controller
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle == .dark {
            preferences.keyboardAppearance = .dark
        } else {
            preferences.keyboardAppearance = .light
        }
        
        let wasFirstResponder = terminalTextView.isFirstResponder
        
        if wasFirstResponder {
            terminalTextView.resignFirstResponder()
        }
        
        terminalTextView.keyboardAppearance = preferences.keyboardAppearance
        
        terminalTextView.inputAccessoryView = nil
        
        assistant = InputAssistantView()
        assistant.trailingActions = [InputAssistantAction(image: LTTerminalViewController.downArrow, target: terminalTextView, action: #selector(terminalTextView.resignFirstResponder))]
        assistant.delegate = self
        assistant.dataSource = self
        
        assistant.attach(to: terminalTextView)
        
        if wasFirstResponder {
            terminalTextView.becomeFirstResponder()
        }
    }
    
    override public var title: String? {
        didSet {
            
            if customTitle != nil && customTitle != title {
                title = customTitle
            }
            
            bookmarkData = try? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).bookmarkData()
            
            if #available(iOS 13.0, *) {
                view.window?.windowScene?.title = title
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name:UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        if traitCollection.userInterfaceStyle == .dark {
            preferences.keyboardAppearance = .dark
        } else {
            preferences.keyboardAppearance = .light
        }
        
        terminalTextView.keyboardAppearance = preferences.keyboardAppearance
        
        view.tintColor = preferences.foregroundColor
        view.backgroundColor = preferences.backgroundColor
        
        LTTerminalViewController.visible_ = self
        shell.io = LTIO(terminal: self)
        
        assistant.delegate = self
        assistant.dataSource = self
        assistant.trailingActions = [InputAssistantAction(image: LTTerminalViewController.downArrow, target: terminalTextView, action: #selector(terminalTextView.resignFirstResponder))]
        assistant.attach(to: terminalTextView)
        
        terminalTextView.keyboardAppearance = preferences.keyboardAppearance
        
        terminalTextView.isEditable = false
        
        for command in shell.history.enumerated() {
            if command.element.isEmpty {
                shell.history.remove(at: command.offset)
                break
            }
        }
        
        if restoredSession {
            terminalTextView.attributedText = attributedConsole
            _ = helpMain(argc: 2, argv: ["help", "--restored"], io: shell.io!)
        } else {
            _ = helpMain(argc: 2, argv: ["help", "--startup"], io: shell.io!)
        }
        
        if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent(".shrc").path) {
            _ = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (_) in
                self.shell.run(command: "sh ~/Documents/.shrc")
            })
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (_) in
            self.shell.input()
        })
        
        lastLogin = Date()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let io = shell.io {
            ios_switchSession(io.stdout)
                
            if let url = self.url {
                self.url = nil
                ios_setDirectoryURL(url)
            }
            
            title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        }
        
        LTTerminalViewController.visible_ = self
        navigationController_ = navigationController
        defaultBarStyle = navigationController?.navigationBar.barStyle ?? .default
        navigationController?.navigationBar.barStyle = preferences.barStyle
        navigationController?.setNeedsStatusBarAppearanceUpdate()
        
        terminalTextView.isEditable = true
        _ = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { (_) in
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
        
        #if targetEnvironment(simulator)
        assistant.attach(to: terminalTextView)
        #else
        if SettingsTableViewController.shouldHideSuggestionsBar.boolValue {
            terminalTextView.inputAccessoryView = nil
        } else {
            assistant.attach(to: terminalTextView)
        }
        #endif
        terminalTextView.reloadInputViews()
        
        (UIApplication.shared.delegate as? AppDelegate)?.movePrograms()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSize()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let wasFirstResponder = terminalTextView.isFirstResponder
        if wasFirstResponder {
            terminalTextView.resignFirstResponder()
        }
        
        coordinator.animate(alongsideTransition: nil) { (_) in
            if wasFirstResponder {
                self.terminalTextView.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - Keyboard

    @objc func keyboardWillShow(_ notification: Notification) {
        let d = notification.userInfo!
        var r = d[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        
        r = terminalTextView.convert(r, from:nil)
        terminalTextView.contentInset.bottom = r.size.height
        terminalTextView.scrollIndicatorInsets.bottom = r.size.height
        
        updateSize()
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        terminalTextView.contentInset = .zero
        terminalTextView.scrollIndicatorInsets = .zero
        
        updateSize()
    }
    
    // MARK: - Text view delegate
    
    public func textViewDidChange(_ textView: UITextView) {
        if !isAskingForInput && !isWrittingToStdin, let attrs = textView.attributedText {
            attributedConsole = NSMutableAttributedString(attributedString: attrs)
        }
        isWrittingToStdin = false
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        (UIApplication.shared.delegate as? AppDelegate)?.movePrograms()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                
        if !isAskingForInput {
            let location: Int = textView.offset(from: textView.beginningOfDocument, to: textView.endOfDocument)
            let length: Int = textView.offset(from: textView.endOfDocument, to: textView.endOfDocument)
            let end = NSMakeRange(location, length)
            
            if end != range && !(text == "" && range.length == 1 && range.location+1 == end.location) {
                // Only allow inserting text from the end
                return false
            }
            
            if (textView.text as NSString).replacingCharacters(in: range, with: text).count >= attributedConsole.string.count {
                
                isWrittingToStdin = !isAskingForInput
                
                self.prompt += text
                
                if text == "\n" {
                    
                    if let data = self.prompt.data(using: .utf8) {
                        tprint("\n")
                        shell.io?.inputPipe.fileHandleForWriting.write(data)
                        self.prompt = ""
                        return false
                    }
                } else if text == "" && range.length == 1 {
                    prompt = String(prompt.dropLast())
                }
                
                return true
            }
        } else if let consoleRange = textView.text.range(of: attributedConsole.string) {
            
            if text == "\n" {
                tprint("\n")
                textViewDidChange(textView)
                isAskingForInput = false
                isWrittingToStdin = false
                
                let prompt = self.prompt
                self.prompt = ""
                
                self.thread = DispatchQueue.global(qos: .utility)
                self.thread.async {
                    self.shell.run(command: prompt)
                    
                    while (self.shell.io?.parserQueue ?? 0) > 0 {
                        sleep(UInt32(0.2))
                    }
                    
                    self.thread.asyncAfter(deadline: .now()+0.2) {
                        self.shell.input()
                    }
                }
                
                return false
            } else {
                
                if text == "" && range.length == 1 && self.prompt.isEmpty { // Delete not allowed
                    return false
                }
                
                if range.location < (attributedConsole.string as NSString).length {
                    return false
                }
                
                var prompt = textView.text ?? ""
                prompt = (prompt as NSString).replacingCharacters(in: range, with: text)
                prompt.replaceSubrange(consoleRange, with: "")
                
                self.prompt = prompt
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
            
            if #available(iOS 13.0, *) {
                UIColor.label.setStroke()
            } else {
                UIColor.black.setStroke()
            }
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
        
        if let command = currentCommand {
            return command.commandInput
        } else if prompt.isEmpty {
            return .history
        } else {
            return .command
        }
    }
    
    private var commands_: [String] {
        
        guard completionType != .running else {
            if shell.isBuiltinRunning {
                return []
            } else {
                return ["Stop", "EOF"]
            }
        }
        
        var suggestions: [String] {
            let flags = currentCommand?.flags ?? []
            if completionType == .none {
                return flags
            } else if completionType == .file, var files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                for item in files.enumerated() {
                    files.remove(at: item.offset)
                    files.insert("\(item.element.replacingOccurrences(of: " ", with: "\\ ").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "'", with: "\\\'"))", at: item.offset)
                }
                return [".", "../"]+files+flags
            } else if completionType == .directory, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                var dirs = [".", "../"]
                for file in files {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) && isDir.boolValue {
                        dirs.append("\(file.replacingOccurrences(of: " ", with: "\\ ").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "'", with: "\\\'"))")
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
                for file in (try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("bin").path)) ?? [] {
                    if file.lowercased().hasSuffix(".py") || file.lowercased().hasSuffix(".ll") || file.lowercased().hasSuffix(".bc") {
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
            if !suggestions_.contains(suggestion) && suggestion.hasPrefix(prompt.components(separatedBy: " ").last ?? "") {
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
        
        let text = (commands_[index]+" ").replacingFirstOccurrence(of: prompt.components(separatedBy: " ").last ?? "", with: "")
        
        if completionType == .running {
            if index == 0 {
                tprint("\u{003}\n")
                return shell.killCommand()
            } else if index == 1 {
                return shell.sendEOF()
            }
        } else {
            prompt += text
        }
        terminalTextView.attributedText = attributedConsole
        tprint(prompt)
    }
    
    // MARK: - Input assistant view data source
    
    public func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    public func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        
        guard commands_.indices.contains(index) else {
            return ""
        }
        
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
            ios_switchSession(shell.io?.stdout)
            ios_setDirectoryURL(urls[0])
            title = urls[0].lastPathComponent
        } else {
            tprint("Error opening \(urls[0].lastPathComponent).\n")
            shell.input()
        }
    }
}

