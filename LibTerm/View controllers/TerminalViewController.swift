//
//  ViewController.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/29/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The terminal interacting with the shell.
class TerminalViewController: UIViewController, UITextViewDelegate {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// The Text view displaying content.
    @IBOutlet weak var terminalTextView: UITextView!
    
    /// The permanent console without the actual user input.
    var console = ""
    
    /// The actual user input.
    var prompt = ""
    
    /// `true` if the shell is asking for input.
    var isAskingForInput = false
    
    /// `true` if a command is asking for input.
    var isWrittingToStdin = false
    
    /// The shell for running command.
    let shell = LibShell()
    
    /// The thrad running the shell.
    let thread = DispatchQueue.global(qos: .userInteractive)
    
    /// Asks the user for a command.
    ///
    /// - Parameters:
    ///     - prompt: The prompt.
    func input(prompt: String) {
        title = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
        tprint(prompt)
        textViewDidChange(terminalTextView)
        isAskingForInput = true
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
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        edgesForExtendedLayout = []
        
        terminalTextView.keyboardAppearance = .dark
        terminalTextView.autocorrectionType = .no
        terminalTextView.smartQuotesType = .no
        terminalTextView.smartDashesType = .no
        terminalTextView.autocapitalizationType = .none
        terminalTextView.delegate = self
        
        shell.io = IO(terminal: self)
        shell.input()
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
        if !isAskingForInput && !isWrittingToStdin {
            console = textView.text
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
        
        if (textView.text as NSString).replacingCharacters(in: range, with: text).count >= console.count {
            
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
}

