//
//  StealthTabApp.swift
//  StealthTab
//
//  Created by Adam on 08/11/25.
//

import SwiftUI

@main
struct StealthTabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                // Handled by ContentView
            }
            
            HistoryCommands()
        }
    }
}

struct HistoryCommands: Commands {
    @FocusedValue(\.browserViewModel) var viewModel: BrowserViewModel?
    
    var body: some Commands {
        CommandMenu("History") {
            Button("Show Full History") {
                viewModel?.openHistoryWindow()
            }
            .keyboardShortcut("y", modifiers: .command)
            .disabled(viewModel == nil)
            
            Divider()
            
            Button("Clear History...") {
                viewModel?.clearHistory()
            }
            .disabled(viewModel == nil)
        }
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
