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

/// The terminal interacting with the shell.
public class LTTerminalViewController: UIViewController, UITextViewDelegate, InputAssistantViewDelegate, InputAssistantViewDataSource, UIDocumentPickerDelegate {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// The Text view displaying content.
   @IBOutlet weak public var terminalTextView: TerminalTextView!
    
    /// The permanent console without the actual user input.
    var attributedConsole = NSMutableAttributedString()
    
    /// The actual user input.
    var prompt = "" {
        didSet {
            assistant.reloadData()
        }
    }
    
    /// `true` if the shell is asking for input.
    var isAskingForInput = false
    
    /// `true` if a command is asking for input.
    var isWrittingToStdin = false
    
    /// The shell for running command.
    public let shell = LibShell()
    
    /// The thrad running the shell.
    let thread = DispatchQueue.global(qos: .userInteractive)
    
    /// The view for autocompletion.
    let assistant = InputAssistantView()
    
    /// Asks the user for a command.
    ///
    /// - Parameters:
    ///     - prompt: The prompt.
    func input(prompt: String) {
        title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        tprint(prompt)
        textViewDidChange(terminalTextView)
        isAskingForInput = true
        assistant.reloadData()
    }
    
    /// Prints the given text.
    ///
    /// - Parameters:
    ///     - text: Text to print.
    public func tprint(_ text: String) {
        
        let newAttrs = NSMutableAttributedString(attributedString: terminalTextView.attributedText ?? NSAttributedString())
        newAttrs.append(NSAttributedString(string: text, attributes: [.font : UIFont(name: "Menlo", size: 14) ?? UIFont.systemFont(ofSize: 14), .foregroundColor: LTForegroundColor]))
        terminalTextView.attributedText = newAttrs
        terminalTextView.scrollToBottom()
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
    
    // MARK: - View controller
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
                
        view.tintColor = LTForegroundColor
        view.backgroundColor = LTBackgroundColor
        
        shell.io = LTIO(terminal: self)
        shell.input()
        
        assistant.delegate = self
        assistant.dataSource = self
        assistant.trailingActions = [InputAssistantAction(image: LTTerminalViewController.downArrow, target: terminalTextView, action: #selector(terminalTextView.resignFirstResponder))]
        assistant.attach(to: terminalTextView)
        
        terminalTextView.keyboardAppearance = LTKeyboardAppearance
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let io = shell.io {
            ios_switchSession(io.ios_stdout)
            ios_setStreams(io.ios_stdin, io.ios_stdout, io.ios_stderr)
            title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        terminalTextView.becomeFirstResponder()
    }
    
    override public func viewDidLayoutSubviews() {
        putenv("COLUMNS=\(Int(terminalTextView.frame.width/14))".cValue)
        putenv("ROWS=\(Int(terminalTextView.frame.height/14))".cValue)
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
                    thread.async {
                        self.shell.run(command: prompt)
                        DispatchQueue.main.async {
                            _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (_) in
                                self.shell.input()
                            })
                        }
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
    
    private var currentCommand: CommandHelp? {
        for command in Commands {
            if command.commandName == prompt.components(separatedBy: " ")[0] {
                return command
            }
        }
        return nil
    }
    
    private var completionType: CommandHelp.CompletionType {
        if let command = currentCommand, prompt.hasSuffix(" ") {
            return command.commandInput
        } else if prompt.isEmpty {
            return .history
        } else {
            return .command
        }
    }
    
    private var commands: [String] {
        var suggestions: [String] {
            let flags = currentCommand?.flags ?? []
            if completionType == .none {
                return flags
            } else if completionType == .file, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                return flags+[".", "../"]+files
            } else if completionType == .directory, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
                var dirs = [".", "../"]
                for file in files {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) && isDir.boolValue {
                        dirs.append(file)
                    }
                }
                return flags+dirs
            } else if completionType == .history {
                var commands_ = shell.history.reversed() as [String]
                for command in Commands {
                    if !commands_.contains(command.commandName) {
                        commands_.append(command.commandName)
                    }
                }
                return commands_
            } else {
                var commands_ = shell.history.reversed() as [String]
                for command in Commands {
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
        var suggestions_ = suggestions
        for suggestion in suggestions {
            if !suggestions_.contains(suggestion) {
                suggestions_.append(suggestion)
            }
        }
        
        return suggestions_
    }
    
    // MARK: - Input assistant view delegate
    
    public func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        if completionType != .command && completionType != .history {
            prompt += commands[index]+" "
        } else {
            prompt = commands[index]+" "
        }
        terminalTextView.attributedText = attributedConsole
        tprint(prompt)
    }
    
    // MARK: - Input assistant view data source
    
    public func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    public func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        
        return commands[index]
    }
    
    public func numberOfSuggestionsInInputAssistantView() -> Int {
        if isAskingForInput {
            return commands.count
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
            FileManager.default.changeCurrentDirectoryPath(urls[0].path)
            title = urls[0].lastPathComponent
        } else {
            tprint("Error opening \(urls[0].lastPathComponent).\n")
            shell.input()
        }
    }
}

