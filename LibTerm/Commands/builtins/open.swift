//
//  open.swift
//  LibTerm
//
//  Created by Adrian Labbe on 11/4/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation
import UIKit

/// The `open` command.
func openMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    if argc == 1 {
        fputs("Usage:\n\(argv[0]) [Items to share ...]\n", io.stdout)
        return 1
    }
    
    var items = [Any]()
    
    for argument in argv.dropFirst() {
        if FileManager.default.fileExists(atPath: argument) {
            items.append(URL(fileURLWithPath: argument, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)))
        } else if let url = URL(string: argument), !url.isFileURL, url.scheme?.isEmpty == false {
            let semaphore = DispatchSemaphore(value: 0)
            var returnValue = 0
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { (success) in
                    semaphore.signal()
                    if !success {
                        returnValue = 1
                    }
                }
            }
            semaphore.wait()
            return Int32(returnValue)
        } else {
            items.append(argument)
        }
    }
    
    DispatchQueue.main.async {
        
        let vc = io.terminal?.parent
        
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = vc?.view.window
        controller.popoverPresentationController?.sourceRect = .zero
        vc?.present(controller, animated: true, completion: nil)
    }
    
    return 0
}
