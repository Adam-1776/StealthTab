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
            // Add custom commands for browser functionality
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    // This could be extended to support multiple tabs
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}
