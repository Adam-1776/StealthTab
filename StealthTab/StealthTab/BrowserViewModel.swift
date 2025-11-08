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
    
    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?
    @Published var urlInput: String = ""
    
    // MARK: - Computed Properties
    
    var activeTab: Tab? {
        guard let activeTabId = activeTabId else { return nil }
        return tabs.first { $0.id == activeTabId }
    }
    
    // MARK: - Initialization
    
    init() {
        // Create initial tab with Google loaded
        let initialTab = Tab(
            urlString: BrowserConfig.defaultHomeURL,
            isNewTab: false
        )
        tabs.append(initialTab)
        activeTabId = initialTab.id
        urlInput = initialTab.urlString
    }
    
    // MARK: - Tab Management
    
    func createNewTab() {
        let newTab = Tab(isNewTab: true)
        tabs.append(newTab)
        switchToTab(newTab.id)
    }
    
    func closeTab(_ tabId: UUID) {
        guard tabs.count > 1 else {
            // Don't close the last tab, just reset it to new tab state
            if let lastTab = tabs.first {
                lastTab.urlString = ""
                lastTab.title = "New Tab"
                lastTab.isNewTab = true
                lastTab.webView = nil
                urlInput = ""
            }
            return
        }
        
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        
        // If closing active tab, switch to another one
        if tabId == activeTabId {
            if index > 0 {
                switchToTab(tabs[index - 1].id)
            } else if index < tabs.count - 1 {
                switchToTab(tabs[index + 1].id)
            }
        }
        
        tabs.remove(at: index)
    }
    
    func switchToTab(_ tabId: UUID) {
        activeTabId = tabId
        if let tab = activeTab {
            urlInput = tab.urlString
        }
    }
    
    // MARK: - Navigation Actions
    
    func goBack() {
        activeTab?.webView?.goBack()
    }
    
    func goForward() {
        activeTab?.webView?.goForward()
    }
    
    func reload() {
        guard let tab = activeTab else { return }
        if tab.isLoading {
            tab.webView?.stopLoading()
        } else {
            tab.webView?.reload()
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
        guard let tab = activeTab else { return }
        
        var urlToLoad = input.trimmingCharacters(in: .whitespaces)
        
        // If it doesn't look like a URL, treat it as a search query
        if !urlToLoad.contains(".") || !urlToLoad.contains("://") {
            urlToLoad = constructSearchURL(query: urlToLoad)
        } else if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        if let url = URL(string: urlToLoad) {
            // Mark tab as no longer new
            tab.isNewTab = false
            tab.urlString = urlToLoad
            
            // Create WebView if it doesn't exist yet
            if tab.webView == nil {
                // WebView will be created when the view updates
            } else {
                tab.webView?.load(URLRequest(url: url))
            }
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
