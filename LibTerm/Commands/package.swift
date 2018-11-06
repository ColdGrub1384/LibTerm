//
//  package.swift
//  LibTerm
//
//  Created by Adrian Labbe on 11/4/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import UIKit
import ios_system
import ObjectUserDefaults

fileprivate let reset = "\u{001b}[0m"
fileprivate let red = "\u{001b}[31m"
fileprivate let green = "\u{001b}[32m"
fileprivate let blue = "\u{001b}[34m"
fileprivate let underline = "\u{001b}[4m"

fileprivate let packagesKey = ObjectUserDefaults.standard.item(forKey: "packages")

fileprivate let scriptsURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("scripts")

/// The `package` command.
func packageMain(argc: Int, argv: [String], shell: LibShell) -> Int32 {
    
    var helpText = "Use this command for installing packages.\n\n"
    helpText += "\(underline)Commands\(reset)\n"
    helpText += "  \(blue)source\(reset): Show the GitHub repo containing all the packages\n"
    helpText += "  \(blue)install\(reset) \(green)package_name ...\(reset): Download and install or update package(s)\n"
    helpText += "  \(blue)remove\(reset) \(green)package_name ...\(reset): Remove package(s)\n"
    
    if argc == 1 {
        fputs(helpText, shell.io?.ios_stdout)
        return 0
    } else if argv[1] == "source" {
        UIApplication.shared.open(URL(string: "https://github.com/ColdGrub1384/LibTerm-Packages")!, options: [:], completionHandler: nil)
        return 0
    } else if argv[1] == "install" {
        
        guard argv.indices.contains(2) else {
            return packageMain(argc: 1, argv: [argv[0]], shell: shell)
        }
        
        var arguments = argv
        arguments.removeFirst()
        arguments.removeFirst()
        
        for package in arguments {
            guard let url = URL(string: "https://github.com/ColdGrub1384/LibTerm-Packages/raw/master/\(argv[2]).zip") else {
                fputs("\(argv[0]): \(package): Invalid package name\n", shell.io?.ios_stderr)
                return 1
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            var returnValue: Int32 = 0 {
                didSet {
                    semaphore.signal()
                }
            }
            
            fputs("\(blue)Downloading \(package)...\(reset)\n", shell.io?.ios_stdout)
            
            URLSession.shared.downloadTask(with: url) { (url, response, error) in
                if let error = error {
                    fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", shell.io?.ios_stderr)
                    returnValue = 1
                }
                
                // A temporary directory is created where the package will be installed. After the package is installed in this temporary directory, the command will index all files inside it to remove them with `package remove`. All files are then moved to the permanent directory where all other packages are installed.
                let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("scripts")
                if !FileManager.default.fileExists(atPath: tmpURL.path) {
                    do {
                        try FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: false, attributes: nil)
                    } catch {
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", shell.io?.ios_stderr)
                        returnValue = 1
                    }
                }
                for file in (try? FileManager.default.contentsOfDirectory(at: tmpURL, includingPropertiesForKeys: nil, options: .init(rawValue: 0))) ?? [] {
                    try? FileManager.default.removeItem(at: file)
                }
                // ---
                
                if var fileURL = url {
                    if let name = response?.suggestedFilename {
                        let newURL = tmpURL.appendingPathComponent(name)
                        do {
                            try FileManager.default.moveItem(at: fileURL, to: newURL)
                            fileURL = newURL
                        } catch {}
                    }
                    fputs("\(blue)Installing \(package)...\(reset)\n", shell.io?.ios_stdout)
                    
                    let cwd = FileManager.default.currentDirectoryPath
                    
                    chdir(tmpURL.path)
                    
                    let unzip = ios_system("tar -xf '\(fileURL.path)'")
                    ios_system("rm '\(fileURL.path)'")
                    
                    guard unzip == 0 else {
                        fputs("\(package) not installed!\n", shell.io?.ios_stderr)
                        returnValue = 1
                        return
                    }
                    
                    do {
                        let packageIndex = try FileManager.default.contentsOfDirectory(atPath: tmpURL.path)
                        
                        if packagesKey.dictionaryValue != nil {
                            packagesKey.dictionaryValue?[package] = packageIndex
                        } else {
                            packagesKey.dictionaryValue = [package : packageIndex]
                        }
                        
                        for file in packageIndex {
                            try FileManager.default.moveItem(atPath: file, toPath: scriptsURL.appendingPathComponent(file).path)
                        }
                        
                        fputs("\(green)\(package) installed!\(reset)\n", shell.io?.ios_stdout)
                        
                        chdir(cwd)
                    } catch {
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)", shell.io?.ios_stderr)
                        returnValue = 1
                        return
                    }
                    
                    returnValue = unzip
                } else {
                    returnValue = 1
                }
            }.resume()
            
            semaphore.wait()
            
            return returnValue
        }
        return 0
    } else if argv[1] == "remove" {
        guard let packages = packagesKey.dictionaryValue as? [String:[String]] else {
            fputs("\(argv[0]): no package is installed\n", shell.io?.ios_stderr)
            return 1
        }
        
        var arguments = argv
        arguments.removeFirst()
        arguments.removeFirst()
        
        for package in arguments {
            if let packageToRemove = packages[package] {
                for path in packageToRemove {
                    do {
                        try FileManager.default.removeItem(at: scriptsURL.appendingPathComponent(path))
                    } catch {
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", shell.io?.ios_stderr)
                        return 1
                    }
                }
            } else {
                fputs("\(argv[0]): \(package): package is not installed\n", shell.io?.ios_stderr)
                return 1
            }
            
            fputs("\(red)\(package) was removed!\(reset)\n", shell.io?.ios_stdout)
        }
        
        return 0
    } else {
        fputs("\(argv[0]): \(argv[1]): command not found\n", shell.io?.ios_stderr)
        return 1
    }
}
