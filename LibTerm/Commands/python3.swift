//
//  python3.swift
//  LibTerm
//
//  Created by Adrian Labbé on 05.01.19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import Foundation

/// The `python` command.
@_cdecl("python3_swift_main") public func python3_swift_main(argc: Int32, argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) -> Int32 {
    return _Py_UnixMain(argc, argv)
}
