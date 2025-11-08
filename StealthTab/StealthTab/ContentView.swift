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
    @FocusState private var isURLBarFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(viewModel: viewModel)
            Divider()
            BrowserToolbar(viewModel: viewModel)
            Divider()
            
            if let activeTab = viewModel.activeTab {
                if activeTab.isNewTab {
                    NewTabView { url in
                        viewModel.loadURL(url)
                    }
                } else {
                    BrowserWebView(tab: activeTab)
                }
            } else {
                EmptyStateView()
            }
        }
        .frame(
            minWidth: BrowserConfig.minimumWindowWidth,
            minHeight: BrowserConfig.minimumWindowHeight
        )
        .onChange(of: viewModel.activeTab?.urlString) { oldValue, newValue in
            if let newValue = newValue, !newValue.isEmpty {
                viewModel.updateURLInput(from: newValue)
            }
        }
        .onChange(of: viewModel.activeTabId) { oldValue, newValue in
            // Update URL bar when switching tabs
            if let tab = viewModel.activeTab {
                viewModel.updateURLInput(from: tab.urlString)
            }
        }
        // Keyboard shortcuts
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyPress(event)
            }
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) -> NSEvent? {
        // Cmd+T - New Tab
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "t" {
            viewModel.createNewTab()
            return nil
        }
        
        // Cmd+W - Close Tab
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
            if let activeTabId = viewModel.activeTabId {
                viewModel.closeTab(activeTabId)
            }
            return nil
        }
        
        // Cmd+L - Focus URL bar
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "l" {
            isURLBarFocused = true
            return nil
        }
        
        // Cmd+R - Reload
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "r" {
            viewModel.reload()
            return nil
        }
        
        // Cmd+[ - Back
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "[" {
            viewModel.goBack()
            return nil
        }
        
        // Cmd+] - Forward
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "]" {
            viewModel.goForward()
            return nil
        }
        
        // Cmd+1 through Cmd+9 - Switch to tab by index
        if event.modifierFlags.contains(.command), 
           let char = event.charactersIgnoringModifiers?.first,
           let digit = Int(String(char)),
           digit >= 1 && digit <= 9 {
            let index = digit - 1
            if index < viewModel.tabs.count {
                viewModel.switchToTab(viewModel.tabs[index].id)
            }
            return nil
        }
        
        return event
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Active Tab")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    var canGoBack: Bool {
        viewModel.activeTab?.canGoBack ?? false
    }
    
    var canGoForward: Bool {
        viewModel.activeTab?.canGoForward ?? false
    }
    
    var isLoading: Bool {
        viewModel.activeTab?.isLoading ?? false
    }
    
    var body: some View {
        Group {
            // Back button
            NavigationButton(
                iconName: "chevron.left",
                action: viewModel.goBack,
                isEnabled: canGoBack,
                tooltip: "Go Back"
            )
            
            // Forward button
            NavigationButton(
                iconName: "chevron.right",
                action: viewModel.goForward,
                isEnabled: canGoForward,
                tooltip: "Go Forward"
            )
            
            // Reload/Stop button
            NavigationButton(
                iconName: isLoading ? "xmark" : "arrow.clockwise",
                action: viewModel.reload,
                isEnabled: true,
                tooltip: isLoading ? "Stop Loading" : "Reload"
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
    
    var isLoading: Bool {
        viewModel.activeTab?.isLoading ?? false
    }
    
    var body: some View {
        HStack(spacing: 8) {
            URLBarIcon(isLoading: isLoading)
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
    @ObservedObject var tab: Tab
    
    var body: some View {
        WebView(tab: tab)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
