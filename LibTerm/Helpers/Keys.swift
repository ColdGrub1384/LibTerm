// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

/// Class hosting special keys as Unicode characters to be sent to SSH.
open class Keys {
    
    /// Returns unicode character from given `Int`.
    ///
    /// - Parameters:
    ///     - dec: Decimal number from wich return unicode character.
    public static func unicode(dec: Int) -> String {
        return String(describing: UnicodeScalar(dec)!)
    }
    
    // From https://en.wikipedia.org/wiki/C0_and_C1_control_codes
    
    // MARK: - Random keys
    
    /// ESC Key.
    public static let esc = unicode(dec: 27)
    
    /// Delete Key.
    public static let delete = unicode(dec: 127)
    
    // MARK: - Function keys
    
    /// F1
    public static let f1 = esc+"OP"
    
    /// F2
    public static let f2 = esc+"OQ"
    
    /// F3
    public static let f3 = esc+"OR"
    
    /// F4
    public static let f4 = esc+"OS"
    
    /// F5
    public static let f5 = esc+"[15~"
    
    /// F6
    public static let f6 = esc+"[17~"
    
    /// F7
    public static let f7 = esc+"[18~"
    
    /// F8
    public static let f8 = esc+"[19~"
    
    /// F9
    public static let f9 = esc+"[20~"
    
    /// F10
    public static let f10 = esc+"[21~"
    
    /// F11
    public static let f11 = esc+"[23~"
    
    /// F12
    public static let f12 = esc+"[24~"
    
    // MARK: - Arrow keys
    
    /// Up Arrow Key.
    public static let arrowUp = esc+"[A"
    
    /// Down Arrow Key.
    public static let arrowDown = esc+"[B"
    
    /// Right Arrow Key.
    public static let arrowRight = esc+"[C"
    
    /// Left Arrow Key.
    public static let arrowLeft = esc+"[D"
    
    
    // MARK: - Control keys
    
    /// ^@
    public static let ctrlAt = unicode(dec: 0)
    
    /// ^A
    public static let ctrlA = unicode(dec: 1)
    
    /// ^B
    public static let ctrlB = unicode(dec: 2)
    
    /// ^C
    public static let ctrlC = unicode(dec: 3)
    
    /// ^D
    public static let ctrlD = unicode(dec: 4)
    
    /// ^E
    public static let ctrlE = unicode(dec: 5)
    
    /// ^F
    public static let ctrlF = unicode(dec: 6)
    
    /// ^G
    public static let ctrlG = unicode(dec: 7)
    
    /// ^H
    public static let ctrlH = unicode(dec: 8)
    
    /// ^I
    public static let ctrlI = unicode(dec: 9)
    
    /// ^J
    public static let ctrlJ = unicode(dec: 10)
    
    /// ^K
    public static let ctrlK = unicode(dec: 11)
    
    /// ^L
    public static let ctrlL = unicode(dec: 12)
    
    /// ^M
    public static let ctrlM = unicode(dec: 13)
    
    /// ^N
    public static let ctrlN = unicode(dec: 14)
    
    /// ^O
    public static let ctrlO = unicode(dec: 15)
    
    /// ^P
    public static let ctrlP = unicode(dec: 16)
    
    /// ^Q
    public static let ctrlQ = unicode(dec: 17)
    
    /// ^R
    public static let ctrlR = unicode(dec: 18)
    
    /// ^S
    public static let ctrlS = unicode(dec: 19)
    
    /// ^T
    public static let ctrlT = unicode(dec: 20)
    
    /// ^U
    public static let ctrlU = unicode(dec: 21)
    
    /// ^V
    public static let ctrlV = unicode(dec: 22)
    
    /// ^W
    public static let ctrlW = unicode(dec: 23)
    
    /// ^X
    public static let ctrlX = unicode(dec: 24)
    
    /// ^Y
    public static let ctrlY = unicode(dec: 25)
    
    /// ^Z
    public static let ctrlZ = unicode(dec: 26)
    
    /// ^\
    public static let ctrlBackslash = unicode(dec: 28)
    
    /// ^]
    public static let ctrlCloseBracket = unicode(dec: 29)
    
    /// ^^
    public static let ctrlCtrl = unicode(dec: 30)
    
    /// ^_
    public static let ctrl_ = unicode(dec: 31)
    
    /// Returns Ctrl key from `String`.
    ///
    /// - Parameters:
    ///     - str: String from wich return the Ctrl key.
    public static func ctrlKey(from str: String) -> String {
        switch str.lowercased() {
        case "a":
            return (Keys.ctrlA)
        case "b":
            return (Keys.ctrlB)
        case "c":
            return (Keys.ctrlC)
        case "d":
            return (Keys.ctrlD)
        case "e":
            return (Keys.ctrlE)
        case "f":
            return (Keys.ctrlF)
        case "g":
            return (Keys.ctrlG)
        case "h":
            return (Keys.ctrlH)
        case "i":
            return (Keys.ctrlI)
        case "j":
            return (Keys.ctrlJ)
        case "k":
            return (Keys.ctrlK)
        case "l":
            return (Keys.ctrlL)
        case "m":
            return (Keys.ctrlM)
        case "n":
            return (Keys.ctrlN)
        case "o":
            return (Keys.ctrlO)
        case "p":
            return (Keys.ctrlP)
        case "q":
            return (Keys.ctrlQ)
        case "r":
            return (Keys.ctrlR)
        case "s":
            return (Keys.ctrlS)
        case "t":
            return (Keys.ctrlT)
        case "u":
            return (Keys.ctrlU)
        case "v":
            return (Keys.ctrlV)
        case "w":
            return (Keys.ctrlW)
        case "x":
            return (Keys.ctrlX)
        case "y":
            return (Keys.ctrlY)
        case "z":
            return (Keys.ctrlZ)
        case "[":
            return (Keys.esc)
        case "\\":
            return (Keys.ctrlBackslash)
        case "]":
            return (Keys.ctrlCloseBracket)
        case "^":
            return (Keys.ctrlCtrl)
        case "_":
            return (Keys.ctrl_)
        default:
            return ""
        }
    }
}
