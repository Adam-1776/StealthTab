//
//  BrowserViewModel.swift
//  StealthTab
//
//  View model for browser state and logic
//

import SwiftUI
import WebKit
import Combine

@MainActor
class BrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var urlString: String
    @Published var urlInput: String
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var pageTitle: String = ""
    @Published var webView: WKWebView?
    
    // MARK: - Initialization
    
    init() {
        self.urlString = BrowserConfig.defaultHomeURL
        self.urlInput = BrowserConfig.defaultHomeURL
    }
    
    // MARK: - Navigation Actions
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        if isLoading {
            webView?.stopLoading()
        } else {
            webView?.reload()
        }
    }
    
    func goHome() {
        loadURL(BrowserConfig.defaultHomeURL)
    }
    
    func clearURLInput() {
        urlInput = ""
    }
    
    // MARK: - URL Loading
    
    func loadURL(_ input: String) {
        var urlToLoad = input.trimmingCharacters(in: .whitespaces)
        
        // If it doesn't look like a URL, treat it as a search query
        if !urlToLoad.contains(".") || !urlToLoad.contains("://") {
            urlToLoad = constructSearchURL(query: urlToLoad)
        } else if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        if let url = URL(string: urlToLoad) {
            webView?.load(URLRequest(url: url))
            urlString = urlToLoad
        }
    }
    
    func updateURLInput(from urlString: String) {
        urlInput = urlString
    }
    
    // MARK: - Private Helpers
    
    private func constructSearchURL(query: String) -> String {
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return BrowserConfig.searchEngineURL + searchQuery
    }
}

