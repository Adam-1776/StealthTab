//
//  HistoryItem.swift
//  StealthTab
//
//  Model representing a browsing history entry
//

import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let url: String
    let title: String
    let visitDate: Date
    
    init(id: UUID = UUID(), url: String, title: String, visitDate: Date = Date()) {
        self.id = id
        self.url = url
        self.title = title
        self.visitDate = visitDate
    }
}

