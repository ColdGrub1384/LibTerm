//
//  ShareViewController.swift
//  Use in LibTerm
//
//  Created by Adrian Labbé on 22-09-19.
//  Copyright © 2019 Adrian Labbe. All rights reserved.
//

import UIKit
import MobileCoreServices

/// A View controller for installing commands.
class ShareViewController: UIViewController {

    /// The Text view that shows current status.
    @IBOutlet weak var textView: UITextView!
    
    /// Completes request.
    @IBAction func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private var appeared = false
    
    // MARK: - View controller
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let attachment = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments?.first else {
            extensionContext?.cancelRequest(withError: NSError(domain: "installation", code: 2, userInfo: [NSLocalizedDescriptionKey : "No input file."]))
            return
        }
        
        guard !appeared else {
            return
        }
        appeared = true
        
        attachment.loadFileRepresentation(forTypeIdentifier: kUTTypeItem as String, completionHandler: { (url, error) in
                        
            guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libterm") else {
                self.extensionContext?.cancelRequest(withError: NSError(domain: "installation", code: 1, userInfo: [NSLocalizedDescriptionKey : "Cannot find shared directory."]))
                return
            }
            
            if let file = url {
                var progName = (attachment.suggestedName ?? file.lastPathComponent).replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: "").lowercased()
                
                if (progName as NSString).pathExtension != file.pathExtension {
                    progName = (progName as NSString).appendingPathExtension(file.pathExtension) ?? progName
                }
                
                DispatchQueue.main.async {
                    self.title = (progName as NSString).deletingPathExtension
                }
                
                if (progName as NSString).deletingPathExtension.isEmpty {
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        self.textView.text = "The file has an invalid name to be used as a program."
                    }
                } else {
                    do {
                        if !FileManager.default.fileExists(atPath: groupURL.path) {
                            try FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true, attributes: [:])
                        }
                        
                        if FileManager.default.fileExists(atPath: groupURL.appendingPathComponent(progName).path) {
                            try FileManager.default.removeItem(at: groupURL.appendingPathComponent(progName))
                        }
                        try FileManager.default.copyItem(at: file, to: groupURL.appendingPathComponent(progName))
                        
                        DispatchQueue.main.async {
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                            self.textView.text = "\((progName as NSString).deletingPathExtension) installed!\nYou can now use '\((progName as NSString).deletingPathExtension)' command as any other command in LibTerm."
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                            self.textView.text = error.localizedDescription
                        }
                    }
                }
            }
        })
    }

}
