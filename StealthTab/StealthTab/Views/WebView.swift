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
    var onPageLoaded: ((String, String) -> Void)?
    
    // MARK: - NSViewRepresentable
    
    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, onPageLoaded: onPageLoaded)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        // Reuse existing webView if available (prevents reload on tab switch)
        if let existingWebView = tab.webView {
            existingWebView.navigationDelegate = context.coordinator
            context.coordinator.setupURLObserver(for: existingWebView)
            return existingWebView
        }
        
        // Create new webView only if it doesn't exist
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
        
        // Setup URL observer for JavaScript navigation (e.g., YouTube)
        context.coordinator.setupURLObserver(for: webView)
        
        // Load initial URL if not empty
        if !tab.urlString.isEmpty, let url = URL(string: tab.urlString) {
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
        var onPageLoaded: ((String, String) -> Void)?
        var urlObserver: NSKeyValueObservation?
        var titleObserver: NSKeyValueObservation?
        var loadingObserver: NSKeyValueObservation?
        var canGoBackObserver: NSKeyValueObservation?
        var canGoForwardObserver: NSKeyValueObservation?
        
        init(tab: Tab, onPageLoaded: ((String, String) -> Void)?) {
            self.tab = tab
            self.onPageLoaded = onPageLoaded
        }
        
        func setupURLObserver(for webView: WKWebView) {
            // Observe URL changes (catches JavaScript navigation like YouTube)
            urlObserver = webView.observe(\.url, options: [.new, .initial]) { [weak self] webView, change in
                guard let self = self,
                      let url = change.newValue as? URL else { return }
                
                let urlString = url.absoluteString
                
                Task { @MainActor in
                    // Update tab's URL
                    if self.tab.urlString != urlString {
                        self.tab.urlString = urlString
                    }
                }
            }
            
            // Observe title changes (ensures title updates correctly on back/forward navigation)
            titleObserver = webView.observe(\.title, options: [.new, .initial]) { [weak self] webView, change in
                guard let self = self,
                      let title = change.newValue as? String,
                      !title.isEmpty else { return }
                
                Task { @MainActor in
                    // Update tab's title whenever it changes
                    if self.tab.title != title {
                        self.tab.title = title
                    }
                }
            }
            
            // Observe loading state (ensures loading indicator stays in sync)
            loadingObserver = webView.observe(\.isLoading, options: [.new, .initial]) { [weak self] webView, change in
                guard let self = self,
                      let isLoading = change.newValue else { return }
                
                Task { @MainActor in
                    self.tab.isLoading = isLoading
                }
            }
            
            // Observe navigation state (canGoBack, canGoForward)
            canGoBackObserver = webView.observe(\.canGoBack, options: [.new, .initial]) { [weak self] webView, change in
                guard let self = self else { return }
                Task { @MainActor in
                    self.tab.canGoBack = change.newValue ?? webView.canGoBack
                }
            }
            
            canGoForwardObserver = webView.observe(\.canGoForward, options: [.new, .initial]) { [weak self] webView, change in
                guard let self = self else { return }
                Task { @MainActor in
                    self.tab.canGoForward = change.newValue ?? webView.canGoForward
                }
            }
        }
        
        deinit {
            urlObserver?.invalidate()
            titleObserver?.invalidate()
            loadingObserver?.invalidate()
            canGoBackObserver?.invalidate()
            canGoForwardObserver?.invalidate()
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
                
                // Add to history
                if let url = webView.url?.absoluteString,
                   let title = webView.title {
                    onPageLoaded?(url, title)
                }
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
