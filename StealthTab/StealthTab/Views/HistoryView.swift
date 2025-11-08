//
//  HistoryView.swift
//  StealthTab
//
//  Full history browser UI
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    let onOpenURL: (String) -> Void
    
    var filteredItems: [HistoryItem] {
        historyManager.search(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Browsing History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear History") {
                    showClearConfirmation()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // History list
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No browsing history" : "No results found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Visit some websites to see your history here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedItems, id: \.key) { group in
                        Section(header: Text(group.key).fontWeight(.semibold)) {
                            ForEach(group.value) { item in
                                HistoryItemRow(item: item, onOpen: {
                                    onOpenURL(item.url)
                                    dismiss()
                                }, onDelete: {
                                    historyManager.deleteItem(item)
                                })
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 700, height: 600)
    }
    
    private var groupedItems: [(key: String, value: [HistoryItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item in
            if calendar.isDateInToday(item.visitDate) {
                return "Today"
            } else if calendar.isDateInYesterday(item.visitDate) {
                return "Yesterday"
            } else if calendar.isDate(item.visitDate, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(item.visitDate, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: item.visitDate)
            }
        }
        
        let order = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { lhs, rhs in
            if let lhsIndex = order.firstIndex(of: lhs.key),
               let rhsIndex = order.firstIndex(of: rhs.key) {
                return lhsIndex < rhsIndex
            }
            return lhs.key > rhs.key
        }
    }
    
    private func showClearConfirmation() {
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
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Text(item.url)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(timeAgo(from: item.visitDate))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete from history")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

#Preview {
    HistoryView(
        historyManager: HistoryManager(),
        onOpenURL: { _ in }
    )
}

