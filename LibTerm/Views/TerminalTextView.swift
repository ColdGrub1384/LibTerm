//
//  TerminalTextView.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/2/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The Text view containing the terminal.
public class TerminalTextView: UITextView {
    
    /// Scrolls to the bottom of the text view.
    func scrollToBottom() {
        let range = NSMakeRange((text as NSString).length - 1, 1)
        scrollRangeToVisible(range)
    }
    
    // MARK: - Text view
    
    override public func caretRect(for position: UITextPosition) -> CGRect {
        let superRect = super.caretRect(for: position)
        if position == endOfDocument {
            return CGRect(x: superRect.origin.x, y: superRect.origin.y, width: 10, height: superRect.height)
        } else {
            return superRect
        }
    }
}
