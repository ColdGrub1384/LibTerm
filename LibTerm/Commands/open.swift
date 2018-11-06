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
        fputs("Usage:\n\(argv[0]) [Items to share ...]", io.stdout)
        return 1
    }
    
    var items = [Any]()
    
    for argument in argv.dropFirst() {
        if FileManager.default.fileExists(atPath: argument) {
            items.append(URL(fileURLWithPath: argument))
        } else if let url = URL(string: argument), !url.isFileURL {
            let semaphore = DispatchSemaphore(value: 0)
            var returnValue = 0
            UIApplication.shared.open(url, options: [:]) { (success) in
                semaphore.signal()
                if !success {
                    returnValue = 1
                }
            }
            semaphore.wait()
            return Int32(returnValue)
        } else {
            items.append(argument)
        }
    }
    
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.popoverPresentationController?.sourceView = UIApplication.shared.keyWindow
    controller.popoverPresentationController?.sourceRect = UIApplication.shared.keyWindow?.bounds ?? .zero
    UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true, completion: nil)
    
    return 0
}
