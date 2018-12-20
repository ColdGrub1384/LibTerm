//
//  clear.swift
//  LibTerm
//
//  Created by Adrian Labbe on 9/30/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation

/// The `clear` command.
func clearMain(_ argc: Int, argv: [String], io: LTIO) -> Int32 {
    DispatchQueue.main.sync {
        io.terminal?.terminalTextView.text = ""
    }
    return 0
}
