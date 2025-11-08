//
//  WebView.swift
//  StealthTab
//
//  WKWebView wrapper for SwiftUI
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @ObservedObject var tab: Tab
    
    // MARK: - NSViewRepresentable
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        
        // Set preferences for proper desktop rendering
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Set a desktop User-Agent to ensure proper rendering
        webView.customUserAgent = BrowserConfig.desktopUserAgent
        
        // Store reference to webView in tab
        tab.webView = webView
        
        // Load initial URL
        if let url = URL(string: tab.urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Updates handled by coordinator
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var tab: Tab
        
        init(tab: Tab) {
            self.tab = tab
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                tab.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                tab.isLoading = false
                tab.updateFromWebView(webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                tab.isLoading = false
            }
            print("Navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                tab.isLoading = false
            }
            print("Provisional navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
