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
class TerminalViewController: UIViewController, UITextViewDelegate, InputAssistantViewDelegate, InputAssistantViewDataSource, UIDocumentPickerDelegate {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// The Text view displaying content.
   @IBOutlet weak var terminalTextView: UITextView!
    
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
    let shell = LibShell()
    
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
    func tprint(_ text: String) {
        let newAttrs = NSMutableAttributedString(attributedString: terminalTextView.attributedText ?? NSAttributedString())
        newAttrs.append(NSAttributedString(string: text, attributes: [.font : UIFont(name: "Menlo", size: 14) ?? UIFont.systemFont(ofSize: 14), .foregroundColor: ForegroundColor]))
        terminalTextView.attributedText = newAttrs
    }
    
    /// Select a new working directory.
    @IBAction func cd(_ sender: Any) {
        let vc = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
        vc.delegate = self
        vc.allowsMultipleSelection = true
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
                
        view.tintColor = ForegroundColor
        view.backgroundColor = BackgroundColor
        
        shell.io = IO(terminal: self)
        shell.input()
        
        assistant.delegate = self
        assistant.dataSource = self
        assistant.trailingActions = [InputAssistantAction(image: TerminalViewController.downArrow, target: terminalTextView, action: #selector(terminalTextView.resignFirstResponder))]
        assistant.attach(to: terminalTextView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let io = shell.io {
            ios_switchSession(io.ios_stdout)
            ios_setStreams(io.ios_stdin, io.ios_stdout, io.ios_stderr)
            title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        terminalTextView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
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
    
    func textViewDidChange(_ textView: UITextView) {
        if !isAskingForInput && !isWrittingToStdin, let attrs = textView.attributedText {
            attributedConsole = NSMutableAttributedString(attributedString: attrs)
        }
        isWrittingToStdin = false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
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
    
    private enum CompletionType {
        case none
        case history
        case command
        case file
        case directory
    }
    
    private var completionType: CompletionType {
        if let completion = operatesOn(prompt.components(separatedBy: " ")[0]), (prompt.hasSuffix(" ") || prompt.components(separatedBy: " ").count == 2), !completion.isEmpty, prompt.components(separatedBy: " ").count < 3 {
            switch completion {
            case "file":
                return .file
            case "directory":
                return .directory
            default:
                return .none
            }
        } else if prompt.isEmpty {
            return .history
        } else {
            return .command
        }
    }
    
    private var commands: [String] {
        if completionType == .file, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
            return [".", "../"]+files
        } else if completionType == .directory, let files = try? FileManager.default.contentsOfDirectory(atPath: FileManager.default.currentDirectoryPath) {
            var dirs = [".", "../"]
            for file in files {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: file, isDirectory: &isDir) && isDir.boolValue {
                    dirs.append(file)
                }
            }
            return dirs
        } else if completionType == .history {
            var commands_ = shell.history.reversed() as [String]
            for command in Commands {
                if !commands_.contains(command) {
                    commands_.append(command)
                }
            }
            return commands_
        } else {
            var commands_ = shell.history.reversed() as [String]
            for command in Commands {
                if command.contains(prompt.components(separatedBy: " ")[0].lowercased()) && !commands_.contains(command) {
                    commands_.append(command)
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
    
    // MARK: - Input assistant view delegate
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, didSelectSuggestionAtIndex index: Int) {
        if completionType != .command && completionType != .history {
            prompt = prompt.components(separatedBy: " ")[0]+" "+commands[index]
        } else {
            prompt = commands[index]+" "
        }
        terminalTextView.attributedText = attributedConsole
        tprint(prompt)
    }
    
    // MARK: - Input assistant view data source
    
    func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        
        return commands[index]
    }
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        return commands.count
    }
    
    // MARK: - Document picker delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if urls.count != 1 {
            let alert = UIAlertController(title: "Select a directory", message: "Please select 1 new working directory. \(urls.count) directories were picked.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.present(controller, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        if urls[0].startAccessingSecurityScopedResource() && FileManager.default.changeCurrentDirectoryPath(urls[0].path) {
            title = urls[0].lastPathComponent
        }
    }
}

