//
//  screenshot.swift
//  LibTerm
//
//  Created by Adrian Labbé on 07-09-19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import UIKit

/// A command to run for App Store screenshots.
func screenshotMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    _ = clearMain(1, argv: ["clear"], io: io)
    _ = helpMain(argc: 1, argv: ["startup", "--startup"], io: io)
    fputs("\(UIDevice.current.name) $ clang -S -emit-llvm 'main.c'\n".cValue, io.stdout)
    fputs("\(UIDevice.current.name) $ lli 'main.ll'\n".cValue, io.stdout)
    fputs("Hello World!\n".cValue, io.stdout)
    
    return 0
}
