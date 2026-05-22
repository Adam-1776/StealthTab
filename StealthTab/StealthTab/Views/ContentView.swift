//
//  ContentView.swift
//  StealthTab
//
//  Main browser UI
//

import SwiftUI
import WebKit
import AppKit

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
                    .id(activeTab.id)
                } else {
                    BrowserWebView(tab: activeTab, viewModel: viewModel)
                        .id(activeTab.id)
                }
            } else {
                EmptyStateView()
            }
        }
        .frame(
            minWidth: BrowserConfig.minimumWindowWidth,
            minHeight: BrowserConfig.minimumWindowHeight
        )
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
        .background {
            WindowAccessor { window in
                viewModel.attachWindow(window)
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            HistoryView(historyManager: viewModel.historyManager) { url in
                viewModel.loadURL(url)
            }
        }
        .focusedSceneValue(\.browserViewModel, viewModel)
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
                .frame(minWidth: 80, maxWidth: .infinity)
                .layoutPriority(0)
            WindowControls(viewModel: viewModel)
                .layoutPriority(1)
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

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
                .foregroundColor(isHovering && isEnabled ? .accentColor : .primary)
                .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering && isEnabled ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.3)
        .help(tooltip)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Window Controls

struct WindowControls: View {
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 8) {
            ToolbarToggleButton(
                iconName: viewModel.isHiddenFromScreenCapture ? "eye.slash" : "eye",
                isActive: viewModel.isHiddenFromScreenCapture,
                action: viewModel.toggleHiddenFromScreenCapture,
                tooltip: viewModel.isHiddenFromScreenCapture ? "Hidden from screen capture" : "Visible to screen capture"
            )

            ToolbarToggleButton(
                iconName: viewModel.staysOnTop ? "pin.fill" : "pin",
                isActive: viewModel.staysOnTop,
                action: viewModel.toggleStaysOnTop,
                tooltip: viewModel.staysOnTop ? "Window stays on top" : "Window uses normal stacking"
            )

            OpacityControl(viewModel: viewModel)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct ToolbarToggleButton: View {
    let iconName: String
    let isActive: Bool
    let action: () -> Void
    let tooltip: String

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
                .foregroundColor(isActive ? .accentColor : .primary)
                .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive || isHovering ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct OpacityControl: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isShowingOpacityPopover = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            OpacitySlider(viewModel: viewModel)

            Button {
                isShowingOpacityPopover.toggle()
            } label: {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
            }
            .buttonStyle(.plain)
            .help("Adjust window transparency")
            .popover(isPresented: $isShowingOpacityPopover, arrowEdge: .bottom) {
                OpacitySlider(viewModel: viewModel)
                    .padding(12)
                    .frame(width: 180)
            }
        }
        .frame(height: BrowserConfig.buttonSize)
    }
}

struct OpacitySlider: View {
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: BrowserConfig.buttonIconSize))
                .foregroundColor(.secondary)
                .help("Window transparency")

            Slider(
                value: $viewModel.windowOpacity,
                in: BrowserConfig.minimumWindowOpacity...1.0
            )
            .frame(width: 88)
            .help("Adjust window transparency")

            Text("\(Int(viewModel.windowOpacity * 100))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 34, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: true, vertical: false)
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


// MARK: - Browser Web View

struct BrowserWebView: View {
    @ObservedObject var tab: Tab
    @ObservedObject var viewModel: BrowserViewModel

    var body: some View {
        WebView(tab: tab) { url, title in
            viewModel.addToHistory(url: url, title: title)
        }
    }
}

// MARK: - Window Accessor

struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)

        DispatchQueue.main.async {
            onResolve(view.window)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onResolve(nsView.window)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
