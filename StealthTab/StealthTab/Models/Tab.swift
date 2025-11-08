//
//  Tab.swift
//  StealthTab
//
//  Model representing a browser tab
//

import Foundation
import WebKit
import Combine

@MainActor
class Tab: Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var urlString: String
    @Published var isLoading: Bool
    @Published var canGoBack: Bool
    @Published var canGoForward: Bool
    @Published var isNewTab: Bool
    var webView: WKWebView?
    
    init(id: UUID = UUID(), 
         title: String = "New Tab",
         urlString: String? = nil,
         isNewTab: Bool = true) {
        self.id = id
        self.title = title
        self.urlString = urlString ?? ""
        self.isLoading = false
        self.canGoBack = false
        self.canGoForward = false
        self.isNewTab = isNewTab
    }
    
    // Convenience method to update tab state from WebView
    func updateFromWebView(_ webView: WKWebView) {
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
        
        if let url = webView.url?.absoluteString {
            self.urlString = url
        }
        
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            self.title = pageTitle
        }
    }
}

