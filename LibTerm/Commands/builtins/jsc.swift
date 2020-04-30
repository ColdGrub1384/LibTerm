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

fileprivate class WebViewDelegate: NSObject, WKUIDelegate, WKScriptMessageHandler {
    
    static let shared = WebViewDelegate()
    
    var vc: UIViewController?
    
    var io: LTIO?
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (_) in
            completionHandler()
        }))
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let stdout = io?.stdout else {
            return
        }
        
        fputs("\((message.body as? String) ?? "")\n", stdout)
    }
}

/// Runs JavaScript.
func jscMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    func help() {
        fputs("\(argv[0]) shows the result of the evaluation of a JavaScript script. To show custom output use the 'console' functions, 'debug()' or 'print()'.\n\nUsage: \(argv[0]) file\n", io.stderr)
    }
    
    guard argv.indices.contains(1) else {
        help()
        return 1
    }
    
    let command = argv[1]
    
    guard command != "-h" && command != "--help" else {
        help()
        return 1
    }
    
    let overrideConsole = """
        function log(emoji, type, args) {
          window.webkit.messageHandlers.logging.postMessage(
            `${emoji} JS ${type}: ${Object.values(args)
              .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
              .map(v => v.substring(0, 3000)) // Limit msg to 3000 chars
              .join(", ")}`
          )
        }

        function debug(text) {
            window.webkit.messageHandlers.logging.postMessage(text)
        }

        function print(text) {
            window.webkit.messageHandlers.logging.postMessage(text)
        }

        let originalLog = console.log
        let originalWarn = console.warn
        let originalError = console.error
        let originalDebug = console.debug

        console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
        console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
        console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
        console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) }
    """
    
    let fileName = URL(fileURLWithPath: command, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).path
    
    let thread_stdout_copy = io.stdout
    let thread_stderr_copy = io.stderr
    var executionDone = false
    do {
        var javascript = try String(contentsOf: URL(fileURLWithPath: fileName), encoding: String.Encoding.utf8)
        javascript = "{" + javascript + "}"
        DispatchQueue.main.async {
            
            WebViewDelegate.shared.vc = io.terminal
            WebViewDelegate.shared.io = io
            
            webView.uiDelegate = WebViewDelegate.shared
            if webView.tag != 2 {
                webView.tag = 2
                webView.configuration.userContentController.add(WebViewDelegate.shared, name: "logging")
            }
            
            webView.evaluateJavaScript(overrideConsole) { (_, _) in
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
                            fputs("\(result ?? "")", thread_stdout_copy)
                            fputs("\n", thread_stdout_copy)
                        }
                        fflush(thread_stdout_copy)
                        fflush(thread_stderr_copy)
                    }
                    executionDone = true
                }
            }
        }
    }
    catch {
      fputs("Error executing JavaScript  file: " + command + ": \(error) \n", thread_stderr_copy)
      executionDone = true
    }
    while (!executionDone) {
        fflush(thread_stdout_copy)
        fflush(thread_stderr_copy)
    }
    
    return 0
}
