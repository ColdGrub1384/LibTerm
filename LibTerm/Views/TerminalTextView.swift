//
//  TerminalTextView.swift
//  LibTerm
//
//  Created by Adrian Labbe on 10/2/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit

/// The Text view containing the terminal.
public class LTTerminalTextView: UITextView {
    
    /// Scrolls to the bottom of the text view.
    func scrollToBottom() {
        let range = NSMakeRange((text as NSString).length - 1, 1)
        scrollRangeToVisible(range)
    }
    
    // MARK: - Text view
    
    override public func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        
        guard let font = self.font else {
            assertionFailure("Could not get font")
            return rect
        }
        
        switch LTTerminalViewController.visible?.preferences.caretStyle.rawValue ?? 0 {
        case 0:
            return rect
            
        case 1:
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charWidth = dummyAtributedString.size().width
            
            rect.size.width = charWidth
            
        case 2:
            let dummyAtributedString = NSAttributedString(string: "X", attributes: [.font: font])
            let charWidth = dummyAtributedString.size().width
            
            rect.origin.y += font.pointSize
            
            rect.size.height = rect.width
            rect.size.width = charWidth
        default:
            break
        }
        
        return rect
    }
}
