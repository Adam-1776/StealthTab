//
//  ContentView.swift
//  StealthTab
//
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var urlString: String = "https://www.google.com"
    @State private var urlInput: String = "https://www.google.com"
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = false
    @State private var pageTitle: String = ""
    @State private var webView: WKWebView?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Back button
                Button(action: {
                    webView?.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!canGoBack)
                .opacity(canGoBack ? 1.0 : 0.3)
                .help("Go Back")
                
                // Forward button
                Button(action: {
                    webView?.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!canGoForward)
                .opacity(canGoForward ? 1.0 : 0.3)
                .help("Go Forward")
                
                // Reload button
                Button(action: {
                    if isLoading {
                        webView?.stopLoading()
                    } else {
                        webView?.reload()
                    }
                }) {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help(isLoading ? "Stop Loading" : "Reload")
                
                // URL bar
                HStack(spacing: 8) {
                    Image(systemName: isLoading ? "arrow.2.circlepath" : "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isLoading ? .blue : .green)
                        .opacity(isLoading ? 0.6 : 0.8)
                    
                    TextField("Enter URL or search...", text: $urlInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit {
                            loadURL(urlInput)
                        }
                    
                    if !urlInput.isEmpty {
                        Button(action: {
                            urlInput = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Home button
                Button(action: {
                    loadURL("https://www.google.com")
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .help("Home")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Web View
            WebViewContainer(
                urlString: $urlString,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                pageTitle: $pageTitle,
                webView: $webView
            )
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: urlString) { oldValue, newValue in
            urlInput = newValue
        }
    }
    
    private func loadURL(_ input: String) {
        var urlToLoad = input.trimmingCharacters(in: .whitespaces)
        
        // If it doesn't look like a URL, treat it as a search query
        if !urlToLoad.contains(".") || !urlToLoad.contains("://") {
            // Use Google search
            let searchQuery = urlToLoad.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlToLoad = "https://www.google.com/search?q=\(searchQuery)"
        } else if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        if let url = URL(string: urlToLoad) {
            webView?.load(URLRequest(url: url))
            urlString = urlToLoad
        }
    }
}

struct WebViewContainer: NSViewRepresentable {
    @Binding var urlString: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    @Binding var webView: WKWebView?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // Load initial URL
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        // Store reference to webView
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Updates handled by coordinator
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            if let url = webView.url?.absoluteString {
                parent.urlString = url
            }
            
            if let title = webView.title {
                parent.pageTitle = title
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("Navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("Provisional navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

#Preview {
    ContentView()
}
