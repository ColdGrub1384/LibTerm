//
//  Clipboard.swift
//  LibTerm
//
//  Created by Adrian Labbe on 11/15/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ios_system

/// The `pbpaste` command.
@_cdecl("pbpaste") public func pbpaste(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    fputs(UIPasteboard.general.string ?? "", thread_stdout)
    return 0
}

/// The `pbcopy` command.
@_cdecl("pbcopy") public func pbcopy(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32 {
    var bytes = [Int8]()
    while true {
        var byte: Int8 = 0
        let count = read(fileno(thread_stdin), &byte, 1)
        guard count == 1 else {
            break
        }
        bytes.append(byte)
    }
    
    let data = Data(bytes: bytes, count: bytes.count)
    
    guard data.count > 0 else {
        return 1
    }
    
    guard let string = String(data: data, encoding: .utf8) else {
        return 1
    }
    
    UIPasteboard.general.string = string
    return 0
}
