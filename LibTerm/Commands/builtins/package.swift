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

fileprivate let scriptsURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("bin")

/// The `package` command.
func packageMain(argc: Int, argv: [String], io: LTIO) -> Int32 {
    
    var helpText = "Use this command for installing packages.\n\n"
    helpText += "\(underline)Commands\(reset)\n"
    helpText += "  \(blue)source\(reset): Show the GitHub repo containing all the packages\n"
    helpText += "  \(blue)list\(reset): Show available packages\n"
    helpText += "  \(blue)install\(reset) \(green)package_name ...\(reset): Download and install or update package(s)\n"
    helpText += "  \(blue)remove\(reset) \(green)package_name ...\(reset): Remove package(s)\n"
    
    if argc == 1 {
        fputs(helpText, io.stdout)
        return 0
    } else if argv[1] == "source" {
        UIApplication.shared.open(URL(string: "https://github.com/ColdGrub1384/LibTerm-Packages")!, options: [:], completionHandler: nil)
        return 0
    } else if argv[1] == "install" {
        
        guard argv.indices.contains(2) else {
            return packageMain(argc: 1, argv: [argv[0]], io: io)
        }
        
        var arguments = argv
        arguments.removeFirst()
        arguments.removeFirst()
        
        for package in arguments {
            guard let url = URL(string: "https://github.com/ColdGrub1384/LibTerm-Packages/raw/master/\(argv[2]).zip") else {
                fputs("\(argv[0]): \(package): Invalid package name\n", io.stderr)
                return 1
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            var returnValue: Int32 = 0 {
                didSet {
                    semaphore.signal()
                }
            }
            
            fputs("\(blue)Downloading \(package)...\(reset)\n", io.stdout)
            
            URLSession.shared.downloadTask(with: url) { (url, response, error) in
                
                if (response as? HTTPURLResponse)?.statusCode == 404 {
                    fputs("\(argv[0]): \(package): Package not found\n", io.stderr)
                    returnValue = 1
                    return
                }
                
                if let error = error {
                    fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", io.stderr)
                    returnValue = 1
                    return
                }
                
                // A temporary directory is created where the package will be installed. After the package is installed in this temporary directory, the command will index all files inside it to remove them with `package remove`. All files are then moved to the permanent directory where all other packages are installed.
                let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("bin")
                if !FileManager.default.fileExists(atPath: tmpURL.path) {
                    do {
                        try FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: false, attributes: nil)
                    } catch {
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", io.stderr)
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
                    fputs("\(blue)Installing \(package)...\(reset)\n", io.stdout)
                    
                    let cwd = FileManager.default.currentDirectoryPath
                    
                    chdir(tmpURL.path)
                    
                    let unzip = ios_system("tar -xf '\(fileURL.path)'")
                    ios_system("rm '\(fileURL.path)'")
                    
                    guard unzip == 0 else {
                        fputs("\(package) not installed!\n", io.stderr)
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
                            let newPath = scriptsURL.appendingPathComponent(file).path
                            if FileManager.default.fileExists(atPath: newPath) {
                                try FileManager.default.removeItem(atPath: newPath)
                            }
                            try FileManager.default.moveItem(atPath: file, toPath: newPath)
                        }
                        
                        fputs("\(green)\(package) installed!\(reset)\n", io.stdout)
                        
                        chdir(cwd)
                    } catch {
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", io.stderr)
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
            fputs("\(argv[0]): no package is installed\n", io.stderr)
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
                        fputs("\(argv[0]): \(package): \(error.localizedDescription)\n", io.stderr)
                        return 1
                    }
                }
            } else {
                fputs("\(argv[0]): \(package): package is not installed\n", io.stderr)
                return 1
            }
            
            fputs("\(red)\(package) was removed!\(reset)\n", io.stdout)
        }
        
        return 0
    } else if argv[1] == "list" {
        
        let semaphore = DispatchSemaphore(value: 0)
        var retValue: Int32? {
            didSet {
                semaphore.signal()
            }
        }
        
        URLSession.shared.dataTask(with: URL(string: "https://api.github.com/repos/ColdGrub1384/LibTerm-Packages/contents")!) { (data, _, error) in
            if let error = error {
                fputs(error.localizedDescription+"\n", io.stderr)
                retValue = 1
            } else if let data = data {
                do {
                    let files = try JSONDecoder().decode([GithubFile].self, from: data)
                    
                    for file in files {
                        guard (file.name as NSString).pathExtension == "zip" else {
                            continue
                        }
                        fputs((file.name as NSString).deletingPathExtension+"\n", io.stdout)
                    }
                    retValue = 0
                } catch {
                    fputs(error.localizedDescription+"\n", io.stderr)
                    retValue = 1
                }
            }
        }.resume()
        
        semaphore.wait()
        return retValue ?? 0
    } else {
        fputs("\(argv[0]): \(argv[1]): command not found\n", io.stderr)
        return 1
    }
}
