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
                // These will be handled by the ContentView when it has focus
                // but we define them here for menu bar consistency
            }
        }
    }
}
