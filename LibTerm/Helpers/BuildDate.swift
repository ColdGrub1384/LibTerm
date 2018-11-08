//
//  Compile.swift
//  LibTerm
//
//  Created by Adrian Labbe on 11/8/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation

/// The date of the build.
var BuildDate: Date {
    if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"), let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath), let infoDate = infoAttr[.creationDate] as? Date {
        return infoDate
    } else {
        return Date()
    }
}
