//
//  HistoryManager.swift
//  StealthTab
//
//  Manages browsing history
//

import Foundation
import Combine

@MainActor
class HistoryManager: ObservableObject {
    @Published var items: [HistoryItem] = []
    
    private let maxHistoryItems = 1000
    private let storageKey = "BrowsingHistory"
    
    // MARK: - Initialization
    
    init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func addItem(url: String, title: String) {
        // Don't add empty URLs or new tab pages
        guard !url.isEmpty, url != "about:blank" else { return }
        
        // Only prevent duplicates if the exact same URL was visited within the last 5 seconds
        if let lastItem = items.first,
           lastItem.url == url,
           Date().timeIntervalSince(lastItem.visitDate) < 5 {
            return
        }
        
        let item = HistoryItem(url: url, title: title)
        items.insert(item, at: 0)
        
        // Keep only recent items
        if items.count > maxHistoryItems {
            items = Array(items.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    func deleteItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func search(query: String) -> [HistoryItem] {
        guard !query.isEmpty else { return items }
        
        let lowercased = query.lowercased()
        return items.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.url.lowercased().contains(lowercased)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        items = decoded
    }
}

