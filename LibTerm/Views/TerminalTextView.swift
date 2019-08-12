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
    
    // MARK: - Text view
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        layoutManager.showsControlCharacters = true
    }
    
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
    
    /// Scrolls to the bottom.
    func scrollToBottom() {
        let textCount: Int = text.count
        guard textCount >= 1 else { return }
        scrollRangeToVisible(NSMakeRange(textCount - 1, 1))
    }
}
