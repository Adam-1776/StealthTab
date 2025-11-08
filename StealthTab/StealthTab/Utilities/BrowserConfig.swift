//
//  BrowserConfig.swift
//  StealthTab
//
//  Configuration and constants for the browser
//

import Foundation

@MainActor
struct BrowserConfig {
    // MARK: - URLs
    static let defaultHomeURL = "https://www.google.com"
    static let searchEngineURL = "https://www.google.com/search?q="
    
    // MARK: - User Agent
    static let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    
    // MARK: - Window Settings
    static let minimumWindowWidth: CGFloat = 800
    static let minimumWindowHeight: CGFloat = 600
    
    // MARK: - UI Settings
    static let toolbarSpacing: CGFloat = 12
    static let toolbarHorizontalPadding: CGFloat = 12
    static let toolbarVerticalPadding: CGFloat = 8
    static let urlBarCornerRadius: CGFloat = 8
    static let urlBarHorizontalPadding: CGFloat = 12
    static let urlBarVerticalPadding: CGFloat = 6
    
    // MARK: - Button Settings
    static let buttonSize: CGFloat = 28
    static let buttonIconSize: CGFloat = 14
    static let urlBarIconSize: CGFloat = 12
}

