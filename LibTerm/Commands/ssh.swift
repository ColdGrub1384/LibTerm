//
//  ssh.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/5/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import StoreKit

func sshMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    guard let helpText = "usage: \(argv[0]) [-p port] user@hostname\n".data(using: .utf8) else {
        return 1
    }
    
    if argc == 1 || argc > 4 {
        shell.io?.outputPipe.fileHandleForWriting.write(helpText)
        return 1
    }
    
    var port = 22
    var address: String!
    
    var i = 0
    for arg in argv {
        if arg == "-p" {
            if argv.indices.contains(i+1), let port_ = Int(argv[i+1]) {
                port = port_
            } else {
                shell.io?.outputPipe.fileHandleForWriting.write(helpText)
                return 1
            }
        } else if arg.components(separatedBy: "@").count == 2 {
            address = arg
        }
        i += i
    }
    
    guard address != nil, let url = URL(string: "\(argv[0])://\(address!):\(port)") else {
        shell.io?.outputPipe.fileHandleForWriting.write(helpText)
        return 1
    }
    
    DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:]) { (success) in
            if !success {
                class StoreDelegate: NSObject, SKStoreProductViewControllerDelegate {
                    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
                        viewController.dismiss(animated: true, completion: nil)
                    }
                    static let shared = StoreDelegate()
                }
                let store = SKStoreProductViewController()
                store.delegate = StoreDelegate.shared
                store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: "1331070425"], completionBlock: nil)
                shell.io?.terminal?.present(store, animated: true, completion: nil)
            }
        }
    }
    
    return 0
}
