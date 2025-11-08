//
//  TabBarView.swift
//  StealthTab
//
//  Tab bar UI component
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.tabs) { tab in
                        TabItem(
                            tab: tab,
                            isActive: tab.id == viewModel.activeTabId,
                            onSelect: { viewModel.switchToTab(tab.id) },
                            onClose: { viewModel.closeTab(tab.id) }
                        )
                    }
                }
            }
            
            // New Tab Button
            Button(action: viewModel.createNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("New Tab")
        }
        .frame(height: 36)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItem: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Favicon / Loading indicator
            if tab.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Tab title
            Text(tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: 150)
            
            // Close button (visible on hover or if active)
            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

