//
//  AppDelegate.swift
//  LibTerm Simulator
//
//  Created by Adrian Labbe on 11/4/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import InputAssistant

/// The app's delegate.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, InputAssistantViewDataSource {

    private static var suggestions = ["ls", "cd ~/Documents", "python", "open document.txt", "echo $HOME", "ls ../Library", "open https://github.com/ColdGrub1384/Pisth"]
    
    private static var downArrow: UIImage {
        return UIGraphicsImageRenderer(size: .init(width: 24, height: 24)).image(actions: { context in
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 1, y: 7))
            path.addLine(to: CGPoint(x: 11, y: 17))
            path.addLine(to: CGPoint(x: 22, y: 7))
            
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
            
            context.cgContext.addPath(path.cgPath)
            
        }).withRenderingMode(.alwaysOriginal)
    }
    
    // MARK: - Application delegate
    
    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        window?.rootViewController?.loadViewIfNeeded()
        
        for view in (window?.rootViewController as? UINavigationController)?.viewControllers.first?.view.subviews ?? [] {
            if let textView = view as? UITextView {
                let assistant = InputAssistantView()
                assistant.dataSource = self
                assistant.trailingActions = [InputAssistantAction(image: AppDelegate.downArrow, target: textView, action: #selector(textView.resignFirstResponder))]
                assistant.attach(to: textView)
            }
        }
    }
    
    // MARK: - Input assistant view data source
    
    func numberOfSuggestionsInInputAssistantView() -> Int {
        return AppDelegate.suggestions.count
    }
    
    func inputAssistantView(_ inputAssistantView: InputAssistantView, nameForSuggestionAtIndex index: Int) -> String {
        return AppDelegate.suggestions[index]
    }
    
    func textForEmptySuggestionsInInputAssistantView() -> String? {
        return nil
    }
}

