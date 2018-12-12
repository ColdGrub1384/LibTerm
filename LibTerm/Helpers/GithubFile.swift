//
//  Package.swift
//  LibTerm
//
//  Created by Adrian Labbe on 12/12/18.
//  Copyright © 2018 Adrian Labbe. All rights reserved.
//

import Foundation

/// A type representing a file in a GitHub repo retrieved with GitHub API.
struct GithubFile: Codable {
    
    /// The name of the file.
    let name: String
    
    /// The path of the file.
    let path: String
    
    private let sha: String
    private let size: Int
    private let url: String
    private let html_url: String
    private let git_url: String
    private let download_url: String
    private let type: String
    private let _links: [String:String]
}
