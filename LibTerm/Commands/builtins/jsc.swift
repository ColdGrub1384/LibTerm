//
//  jsc.swift
//  ios_system
//
//  Created by Nicolas Holzschuch on 01/04/2020.
//  Copyright © 2020 Nicolas Holzschuch. All rights reserved.
//
import Foundation
import ios_system
import WebKit

fileprivate let webView = WKWebView()

fileprivate class WebViewDelegate: NSObject, WKUIDelegate {
    
    static let shared = WebViewDelegate()
    
    var vc: UIViewController?
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
            completionHandler()
        }))
        
        vc?.present(alert, animated: true, completion: nil)
    }
}

/// Runs JavaScript.
func jscMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    let command = argv[1]
    let fileName = URL(fileURLWithPath: command, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path
    
    let thread_stdout_copy = io.stdout
    let thread_stderr_copy = io.stderr
    var executionDone = false
    do {
        var javascript = try String(contentsOf: URL(fileURLWithPath: fileName), encoding: String.Encoding.utf8)
        javascript = "{" + javascript + "}"
        DispatchQueue.main.async {
            
            WebViewDelegate.shared.vc = io.terminal
            
            webView.uiDelegate = WebViewDelegate.shared
            webView.evaluateJavaScript(javascript) { (result, error) in
                if error != nil {
                    // Extract information about *where* the error is, etc.
                    let userInfo = (error! as NSError).userInfo
                    fputs("jsc: Error ", thread_stderr_copy)
                    // WKJavaScriptExceptionSourceURL is hterm.html, of course.
                    fputs("in file " + command + " ", thread_stderr_copy)
                    if let line = userInfo["WKJavaScriptExceptionLineNumber"] as? Int32 {
                        fputs("at line \(line)", thread_stderr_copy)
                    }
                    if let column = userInfo["WKJavaScriptExceptionColumnNumber"] as? Int32 {
                        fputs(", column \(column): ", thread_stderr_copy)
                    } else {
                        fputs(": ", thread_stderr_copy)
                    }
                    if let message = userInfo["WKJavaScriptExceptionMessage"] as? String {
                        fputs(message + "\n", thread_stderr_copy)
                    }
                    fflush(thread_stderr_copy)
                }
                if (result != nil) {
                    if let string = result! as? String {
                        fputs(string, thread_stdout_copy)
                        fputs("\n", thread_stdout_copy)
                    }  else if let number = result! as? Int32 {
                        fputs("\(number)", thread_stdout_copy)
                        fputs("\n", thread_stdout_copy)
                    } else if let number = result! as? Float {
                        fputs("\(number)", thread_stdout_copy)
                        fputs("\n", thread_stdout_copy)
                    } else {
                        fputs("\(result)", thread_stdout_copy)
                        fputs("\n", thread_stdout_copy)
                    }
                    fflush(thread_stdout_copy)
                    fflush(thread_stderr_copy)
                }
                executionDone = true
            }
        }
    }
    catch {
      fputs("Error executing JavaScript  file: " + command + ": \(error) \n", thread_stderr)
      executionDone = true
    }
    while (!executionDone) {
        fflush(thread_stdout)
        fflush(thread_stderr)
    }
    
    return 0
}
