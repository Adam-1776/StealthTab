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
    @Published var isHiddenFromScreenCapture: Bool = UserDefaults.standard.object(forKey: BrowserPreferences.isHiddenFromScreenCapture) as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isHiddenFromScreenCapture, forKey: BrowserPreferences.isHiddenFromScreenCapture)
            scheduleWindowSettingsApply()
        }
    }
    @Published var windowOpacity: Double = UserDefaults.standard.object(forKey: BrowserPreferences.windowOpacity) as? Double ?? 1.0 {
        didSet {
            UserDefaults.standard.set(clampedWindowOpacity, forKey: BrowserPreferences.windowOpacity)
            applyWindowSettings()
        }
    }
    @Published var staysOnTop: Bool = UserDefaults.standard.object(forKey: BrowserPreferences.staysOnTop) as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(staysOnTop, forKey: BrowserPreferences.staysOnTop)
            applyWindowSettings()
        }
    }

    // MARK: - History Manager

    let historyManager = HistoryManager()

    // MARK: - Private Properties

    private var tabObservers: [UUID: AnyCancellable] = [:]
    private var windowVisibilityObservers: Set<AnyCancellable> = []
    private weak var browserWindow: NSWindow?
    private var defaultCollectionBehavior: NSWindow.CollectionBehavior?
    private var defaultWindowLevel: NSWindow.Level?
    private var defaultStyleMask: NSWindow.StyleMask?
    private var lastAppliedStaysOnTopActivationState: Bool?

    // MARK: - Computed Properties

    var activeTab: Tab? {
        guard let activeTabId = activeTabId else { return nil }
        return tabs.first { $0.id == activeTabId }
    }

    private var clampedWindowOpacity: Double {
        clampedOpacity(windowOpacity)
    }

    // MARK: - Initialization

    init() {
        windowOpacity = clampedWindowOpacity

        // Create initial tab with Google loaded
        let initialTab = Tab(
            urlString: BrowserConfig.defaultHomeURL,
            isNewTab: false
        )
        tabs.append(initialTab)
        observeTab(initialTab)
        activeTabId = initialTab.id
        urlInput = initialTab.urlString
        observeWindowVisibilityChanges()
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

    // MARK: - Window Privacy

    func attachWindow(_ window: NSWindow?) {
        guard let window = window else { return }

        if browserWindow !== window {
            defaultCollectionBehavior = window.collectionBehavior
            defaultWindowLevel = window.level
            defaultStyleMask = window.styleMask
        }

        browserWindow = window
        applyWindowSettings()
    }

    func toggleHiddenFromScreenCapture() {
        isHiddenFromScreenCapture.toggle()
    }

    func toggleStaysOnTop() {
        staysOnTop.toggle()
    }

    func cycleWindowOpacityPreset() {
        let currentOpacity = clampedWindowOpacity
        let nextOpacity = BrowserConfig.windowOpacityKeyboardPresets.first {
            $0 > currentOpacity + 0.01
        } ?? BrowserConfig.windowOpacityKeyboardPresets[0]

        windowOpacity = nextOpacity
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

    private func scheduleWindowSettingsApply() {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.applyWindowSettings()
        }
    }

    private func applyWindowSettings() {
        guard let window = browserWindow else { return }

        window.sharingType = isHiddenFromScreenCapture ? .none : .readOnly
        window.collectionBehavior = collectionBehavior(for: window)
        window.styleMask = styleMask(for: window)
        window.hidesOnDeactivate = !staysOnTop
        window.level = staysOnTop ? .screenSaver : (defaultWindowLevel ?? .normal)
        applyActivationPolicyIfNeeded()

        if staysOnTop {
            restorePinnedWindowIfNeeded()
        }

        let opacity = clampedWindowOpacity
        window.alphaValue = CGFloat(opacity)
        window.isOpaque = opacity >= 1.0
        window.backgroundColor = opacity >= 1.0 ? .windowBackgroundColor : .clear
    }

    private func collectionBehavior(for window: NSWindow) -> NSWindow.CollectionBehavior {
        guard staysOnTop else {
            return defaultCollectionBehavior ?? window.collectionBehavior
        }

        return [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
    }

    private func styleMask(for window: NSWindow) -> NSWindow.StyleMask {
        var styleMask = defaultStyleMask ?? window.styleMask

        if staysOnTop {
            styleMask.insert(.nonactivatingPanel)
        }

        return styleMask
    }

    private func observeWindowVisibilityChanges() {
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                self?.restorePinnedWindowSoon()
            }
            .store(in: &windowVisibilityObservers)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.restorePinnedWindowSoon()
            }
            .store(in: &windowVisibilityObservers)
    }

    private func restorePinnedWindowSoon() {
        restorePinnedWindowIfNeeded()

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            self?.restorePinnedWindowIfNeeded()
        }
    }

    private func restorePinnedWindowIfNeeded() {
        guard staysOnTop, let window = browserWindow else { return }

        window.collectionBehavior = collectionBehavior(for: window)
        window.styleMask = styleMask(for: window)
        window.hidesOnDeactivate = false
        window.level = .screenSaver
        window.orderFrontRegardless()
    }

    private func applyActivationPolicyIfNeeded() {
        guard lastAppliedStaysOnTopActivationState != staysOnTop else { return }

        NSApp.setActivationPolicy(staysOnTop ? .accessory : .regular)
        lastAppliedStaysOnTopActivationState = staysOnTop
    }

    private func clampedOpacity(_ opacity: Double) -> Double {
        min(max(opacity, BrowserConfig.minimumWindowOpacity), 1.0)
    }
}

private enum BrowserPreferences {
    static let isHiddenFromScreenCapture = "isHiddenFromScreenCapture"
    static let windowOpacity = "windowOpacity"
    static let staysOnTop = "staysOnTop"
}
