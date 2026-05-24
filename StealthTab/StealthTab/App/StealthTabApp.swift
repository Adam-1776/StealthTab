//
//  StealthTabApp.swift
//  StealthTab
//
//  Created by Adam on 08/11/25.
//

import SwiftUI
import AppKit

@main
struct StealthTabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appDelegate.showBrowserWindow()
                    appDelegate.browserViewModel.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)
            }

            CommandMenu("History") {
                Button("Show Full History") {
                    appDelegate.showBrowserWindow()
                    appDelegate.browserViewModel.openHistoryWindow()
                }
                .keyboardShortcut("y", modifiers: .command)

                Divider()

                Button("Clear History...") {
                    appDelegate.browserViewModel.clearHistory()
                }
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let browserViewModel = BrowserViewModel()

    private var browserWindowController: StealthPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        showBrowserWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func showBrowserWindow() {
        if browserWindowController == nil {
            browserWindowController = StealthPanelController(viewModel: browserViewModel)
        }

        browserWindowController?.showWindow(nil)

        if browserViewModel.staysOnTop {
            browserWindowController?.window?.orderFrontRegardless()
        } else {
            browserWindowController?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

final class StealthPanelController: NSWindowController {
    init(viewModel: BrowserViewModel) {
        let contentView = ContentView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)
        let panel = StealthPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        panel.title = "StealthTab"
        panel.contentView = hostingView
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.worksWhenModal = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.minSize = NSSize(
            width: BrowserConfig.minimumWindowWidth,
            height: BrowserConfig.minimumWindowHeight
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.center()

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class StealthPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

// MARK: - Focused Values

struct BrowserViewModelKey: FocusedValueKey {
    typealias Value = BrowserViewModel
}

extension FocusedValues {
    var browserViewModel: BrowserViewModel? {
        get { self[BrowserViewModelKey.self] }
        set { self[BrowserViewModelKey.self] = newValue }
    }
}
