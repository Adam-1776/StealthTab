//
//  TabBarView.swift
//  StealthTab
//
//  Tab bar UI component
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isNewTabHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabItem(
                            tab: tab,
                            isActive: tab.id == viewModel.activeTabId,
                            isLast: index == viewModel.tabs.count - 1,
                            onSelect: { viewModel.switchToTab(tab.id) },
                            onClose: { viewModel.closeTab(tab.id) }
                        )
                    }
                }
            }
            
            // New Tab Button
            Button(action: viewModel.createNewTab) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isNewTabHovering ? .accentColor : .primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isNewTabHovering ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("New Tab (⌘T)")
            .onHover { hovering in
                isNewTabHovering = hovering
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 36)
        //.background(Color(red: 0.80, green: 0.80, blue: 0.80))
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItem: View {
    @ObservedObject var tab: Tab
    let isActive: Bool
    let isLast: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    @State private var isCloseButtonHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
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
                
                // Close button (always present, but invisible when not hovering)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isCloseButtonHovering ? .red : .secondary)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(isCloseButtonHovering ? Color.red.opacity(0.1) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("Close Tab (⌘W)")
                .onHover { hovering in
                    isCloseButtonHovering = hovering
                }
                .opacity((isHovering || isActive) ? 1.0 : 0.0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color(nsColor: .controlBackgroundColor) : (isHovering ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear))
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
            
            // Divider on the right (except for last tab)
            if !isLast {
                Rectangle()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 1, height: 24)
                    .padding(.horizontal, 8)
            }
        }
    }
}

