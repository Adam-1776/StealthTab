//
//  BrowserViewModel.swift
//  StealthTab
//
//  View model for browser state and logic
//

import SwiftUI
import WebKit
import Combine
import AppKit

@MainActor
class BrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?
    @Published var urlInput: String = ""
    @Published var showHistory: Bool = false
    
    // MARK: - History Manager
    
    let historyManager = HistoryManager()
    
    // MARK: - Private Properties
    
    private var tabObservers: [UUID: AnyCancellable] = [:]
    
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
        observeTab(initialTab)
        activeTabId = initialTab.id
        urlInput = initialTab.urlString
    }
    
    // MARK: - Tab Management
    
    func createNewTab() {
        let newTab = Tab(isNewTab: true)
        tabs.append(newTab)
        observeTab(newTab)
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
        
        // Remove observer
        tabObservers[tabId]?.cancel()
        tabObservers.removeValue(forKey: tabId)
        
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
        
        let urlToLoad = Utils.processInput(input)
        
        if let url = URL(string: urlToLoad) {
            // Mark tab as no longer new
            tab.isNewTab = false
            tab.urlString = urlToLoad
            urlInput = urlToLoad
            
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
    
    // MARK: - History Management
    
    func addToHistory(url: String, title: String) {
        historyManager.addItem(url: url, title: title)
    }
    
    func openHistoryWindow() {
        showHistory = true
    }
    
    func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear All History?"
        alert.informativeText = "This will permanently delete your browsing history. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            historyManager.clearHistory()
        }
    }
    
    // MARK: - Private Methods
    
    private func observeTab(_ tab: Tab) {
        let observer = tab.$urlString
            .sink { [weak self] urlString in
                guard let self = self,
                      tab.id == self.activeTabId,
                      !urlString.isEmpty else { return }
                self.urlInput = urlString
            }
        tabObservers[tab.id] = observer
    }
}
