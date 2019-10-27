//
//  RunScriptIntentHandler.swift
//  Pyto Intents
//
//  Created by Adrian Labbé on 30-07-19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import Intents
import ios_system

class RunCommandIntentHandler: NSObject, RunCommandIntentHandling {
    
    private enum PythonVersion {
        
        case v2_7
        case v3_7
    }
    
    private func setPythonEnvironment(version: PythonVersion) {
        
        guard let py2Path = Bundle.main.path(forResource: "python27", ofType: "zip") else {
            fatalError()
        }
        
        let py2SitePackages = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("site-packages2").path
        
        guard let py3Path = Bundle.main.path(forResource: "python37", ofType: "zip") else {
            fatalError()
        }
        
        let py3SitePackages = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("site-packages3").path
        
        let bundledSitePackages = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("site-packages").path
        let bundledSitePackages3 = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("site-packages3").path
        
        putenv("PYTHONHOME=\(Bundle.main.bundlePath)".cValue)
        
        if version == .v2_7 {
            putenv("PYTHONPATH=\(py2SitePackages):\(py2Path):\(bundledSitePackages)".cValue)
        } else if version == .v3_7 {
            putenv("PYTHONPATH=\(py3SitePackages):\(py3Path):\(bundledSitePackages):\(bundledSitePackages3)".cValue)
        }
    }
    
    func handle(intent: RunCommandIntent, completion: @escaping (RunCommandIntentResponse) -> Void) {
        sideLoading = true
                
        let output = Pipe()
        
        let inputURL = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask)[0].appendingPathComponent("input.txt")
        if !FileManager.default.fileExists(atPath: inputURL.path) {
            FileManager.default.createFile(atPath: inputURL.path, contents: nil, attributes: nil)
        }
        try? intent.input?.write(to: inputURL, atomically: true, encoding: .utf8)
        
        let _stdout = fdopen(output.fileHandleForWriting.fileDescriptor, "w")
        let _stderr = fdopen(output.fileHandleForWriting.fileDescriptor, "w")
        let _stdin = fopen(inputURL.path.cValue, "r")
        
        initializeEnvironment()
        unsetenv("TERM")
        unsetenv("LSCOLORS")
        unsetenv("CLICOLOR")
        putenv("SHAREDDIR=\(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libterm")?.path ?? "")".cValue)
        try? FileManager.default.copyItem(at: Bundle.main.url(forResource: "cacert", withExtension: "pem")!, to: FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0].appendingPathComponent("cacert.pem"))
        
        ios_switchSession(_stdout)
        ios_setStreams(_stdin, _stdout, _stderr)
        ios_setDirectoryURL(FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0])
        
        if intent.command?.hasPrefix("python2 ") == true {
            setPythonEnvironment(version: .v2_7)
        } else {
            setPythonEnvironment(version: .v3_7)
        }
        
        var command = intent.command ?? ""
        var arguments = command.arguments
        
        let scriptsDirectory = (FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.libtermbin") ?? FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]).appendingPathComponent("Documents")
        
        let url: URL
        let _command: String
        
        let llURL = scriptsDirectory.appendingPathComponent(arguments[0]+".ll")
        let bcURL = scriptsDirectory.appendingPathComponent(arguments[0]+".bc")
        let binURL = scriptsDirectory.appendingPathComponent(arguments[0])
        let scriptURL = scriptsDirectory.appendingPathComponent(arguments[0]+".py")
        
        if FileManager.default.fileExists(atPath: binURL.path) {
            url = binURL
            _command = "lli"
        } else if FileManager.default.fileExists(atPath: llURL.path) {
            url = llURL
            _command = "lli"
        } else if FileManager.default.fileExists(atPath: bcURL.path) {
            url = bcURL
            _command = "lli"
        } else {
            url = scriptURL
            _command = "python"
        }
        
        if FileManager.default.fileExists(atPath: url.path) {
            arguments.insert(_command, at: 0)
            arguments.remove(at: 1)
            arguments.insert(url.path, at: 1)
            command = arguments.joined(separator: " ")
        }
                
        var retValue: Int32 = 0
        
        if let cwd = intent.cwd, !cwd.isEmpty {
            ios_system("cd \(cwd.replacingOccurrences(of: " ", with: "\\ ").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "'", with: "\\'"))")
        } else {
            ios_system("cd $SHAREDDIR")
        }
        retValue = ios_system(command)
        
        let response = RunCommandIntentResponse(code: retValue == 0 ? .success : .failure, userActivity: nil)
        
        let outputStr = String(data: output.fileHandleForReading.availableData, encoding: .utf8) ?? ""
        if !outputStr.replacingOccurrences(of: "\n", with: "").isEmpty {
            response.output = outputStr
        }
        
        return completion(response)
    }
    
    func resolveCommand(for intent: RunCommandIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let command = intent.command else {
            return
        }
        
        return completion(.success(with: command))
    }
    
    func resolveCwd(for intent: RunCommandIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let cwd = intent.cwd else {
            return completion(.success(with: ""))
        }
        
        return completion(.success(with: cwd))
    }
    
    func resolveInput(for intent: RunCommandIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let input = intent.input else {
            return completion(.success(with: ""))
        }
        
        return completion(.success(with: input))
    }
}
