//
//  Theming.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/9/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

fileprivate var foregroundColor: UIColor?
fileprivate var backgroundColor: UIColor?

/// Terminal's keyboard appearance.
public var LTKeyboardAppearance = UIKeyboardAppearance.dark

/// Terminal's foreground color.
public var LTForegroundColor: UIColor {
    set {
        foregroundColor = newValue
    }
    get {
        if #available(iOS 11.0, *) {
            return foregroundColor ?? UIColor(named: "Foreground Color")!
        } else {
            return foregroundColor ?? .green
        }
    }
}

/// Terminal's background color.
public var LTBackgroundColor: UIColor {
    set {
        backgroundColor = newValue
    }
    get {
        if #available(iOS 11.0, *) {
            return backgroundColor ?? UIColor(named: "Background Color")!
        } else {
            return backgroundColor ?? .black
        }
    }
}

/// The nav bar's style.
public var LTBarStyle = UIBarStyle.black
