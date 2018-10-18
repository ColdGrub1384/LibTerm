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
fileprivate var fontSize: Double?
fileprivate var caretStyle = 0

/// Caret styles used in the terminal.
public enum LTCaretStyle: Int {
    
    /// The default text view's caret style.
    case verticalBar = 0
    
    /// A block.
    case block = 1
    
    /// An horizontal bar.
    case underline = 2
}

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

/// The terminal's font size.
public var LTFontSize: Double {
    get {
        #if FRAMEWORK
            return fontSize ?? 14
        #else
            let fontSize_ = SettingsTableViewController.fontSize.doubleValue
            if fontSize_ == 0 {
                return fontSize ?? 14
            } else {
                return fontSize_
            }
        #endif
    }
    set {
        #if FRAMEWORK
            fontSize = newValue
        #else
            SettingsTableViewController.fontSize.doubleValue = newValue
        #endif
    }
}

/// The terminal's caret style.
public var LTCaretStyle_: LTCaretStyle {
    get {
        #if FRAMEWORK
            return LTCaretStyle(rawValue: caretStyle)
        #else
            return LTCaretStyle(rawValue: SettingsTableViewController.caretStyle.integerValue) ?? 0
        #endif
    }
    set {
        #if FRAMEWORK
            caretStyle = newValue
        #else
        SettingsTableViewController.caretStyle.integerValue = newValue.rawValue
        #endif
    }
}

/// The nav bar's style.
public var LTBarStyle = UIBarStyle.black
