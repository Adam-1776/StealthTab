//
//  ContentView.swift
//  StealthTab
//
//  Main browser UI
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = BrowserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            BrowserToolbar(viewModel: viewModel)
            Divider()
            BrowserWebView(viewModel: viewModel)
        }
        .frame(
            minWidth: BrowserConfig.minimumWindowWidth,
            minHeight: BrowserConfig.minimumWindowHeight
        )
        .onChange(of: viewModel.urlString) { oldValue, newValue in
            viewModel.updateURLInput(from: newValue)
        }
    }
}

// MARK: - Browser Toolbar

struct BrowserToolbar: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: BrowserConfig.toolbarSpacing) {
            NavigationButtons(viewModel: viewModel)
            URLBar(viewModel: viewModel)
            HomeButton(viewModel: viewModel)
        }
        .padding(.horizontal, BrowserConfig.toolbarHorizontalPadding)
        .padding(.vertical, BrowserConfig.toolbarVerticalPadding)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Navigation Buttons

struct NavigationButtons: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        Group {
            // Back button
            NavigationButton(
                iconName: "chevron.left",
                action: viewModel.goBack,
                isEnabled: viewModel.canGoBack,
                tooltip: "Go Back"
            )
            
            // Forward button
            NavigationButton(
                iconName: "chevron.right",
                action: viewModel.goForward,
                isEnabled: viewModel.canGoForward,
                tooltip: "Go Forward"
            )
            
            // Reload/Stop button
            NavigationButton(
                iconName: viewModel.isLoading ? "xmark" : "arrow.clockwise",
                action: viewModel.reload,
                isEnabled: true,
                tooltip: viewModel.isLoading ? "Stop Loading" : "Reload"
            )
        }
    }
}

struct NavigationButton: View {
    let iconName: String
    let action: () -> Void
    let isEnabled: Bool
    let tooltip: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
                .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.3)
        .help(tooltip)
    }
}

// MARK: - URL Bar

struct URLBar: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            URLBarIcon(isLoading: viewModel.isLoading)
            URLTextField(viewModel: viewModel)
            
            if !viewModel.urlInput.isEmpty {
                ClearButton(action: viewModel.clearURLInput)
            }
        }
        .padding(.horizontal, BrowserConfig.urlBarHorizontalPadding)
        .padding(.vertical, BrowserConfig.urlBarVerticalPadding)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(BrowserConfig.urlBarCornerRadius)
    }
}

struct URLBarIcon: View {
    let isLoading: Bool
    
    var body: some View {
        Image(systemName: isLoading ? "arrow.2.circlepath" : "lock.fill")
            .font(.system(size: BrowserConfig.urlBarIconSize))
            .foregroundColor(isLoading ? .blue : .green)
            .opacity(isLoading ? 0.6 : 0.8)
    }
}

struct URLTextField: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        TextField("Enter URL or search...", text: $viewModel.urlInput)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .onSubmit {
                viewModel.loadURL(viewModel.urlInput)
            }
    }
}

struct ClearButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: BrowserConfig.urlBarIconSize))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Button

struct HomeButton: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        Button(action: viewModel.goHome) {
            Image(systemName: "house.fill")
                .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
                .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
        }
        .buttonStyle(.plain)
        .help("Home")
    }
}

// MARK: - Browser Web View

struct BrowserWebView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        WebView(
            urlString: $viewModel.urlString,
            canGoBack: $viewModel.canGoBack,
            canGoForward: $viewModel.canGoForward,
            isLoading: $viewModel.isLoading,
            pageTitle: $viewModel.pageTitle,
            webView: $viewModel.webView
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
