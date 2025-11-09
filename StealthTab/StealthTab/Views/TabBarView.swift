//
//  TabBarView.swift
//  StealthTab
//
//  Tab bar UI component
//

import SwiftUI

// Custom shape that only rounds the top corners
struct TopRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                         control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                         control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}

struct TabBarView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @State private var isNewTabHovering = false
    
    // Adaptive colors that work in both light and dark mode
    static var tabBarColor: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    static var tabHoveringColor: Color {
        // More visible hover effect using selected content background with low opacity
        Color(nsColor: .selectedContentBackgroundColor).opacity(0.3)
    }
    
    static var toolBarColor: Color {
        // Active tab uses unemphasized selected background
        Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
    }
    
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
                .padding(.leading, 8)
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
        .background(Self.tabBarColor)
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
            .padding(.top, 6)
            .padding(.bottom, 6)
            .background(
                ZStack {
                    TopRoundedRectangle(cornerRadius: 7)
                        .fill(isActive ? TabBarView.toolBarColor : TabBarView.tabBarColor)
                    
                    // Hover overlay for visible feedback
                    if isHovering && !isActive {
                        TopRoundedRectangle(cornerRadius: 7)
                            .fill(TabBarView.tabHoveringColor)
                    }
                }
            )
            .overlay(
                TopRoundedRectangle(cornerRadius: 7)
                    .stroke(Color.clear, lineWidth: 1)
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

