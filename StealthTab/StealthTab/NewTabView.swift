//
//  NewTabView.swift
//  StealthTab
//
//  New tab screen UI
//

import SwiftUI

struct NewTabView: View {
    let onNavigate: (String) -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue.gradient)
                
                Text("New Tab")
                    .font(.system(size: 32, weight: .medium))
            }
            
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search or enter URL", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .onSubmit {
                            if !searchText.isEmpty {
                                onNavigate(searchText)
                                searchText = ""
                            }
                        }
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                .frame(maxWidth: 600)
                
                Text("Press Enter to navigate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quick links (optional)
            VStack(spacing: 16) {
                Text("Quick Links")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    QuickLinkButton(
                        icon: "magnifyingglass",
                        title: "Google",
                        action: { onNavigate("https://www.google.com") }
                    )
                    
                    QuickLinkButton(
                        icon: "newspaper",
                        title: "News",
                        action: { onNavigate("https://news.google.com") }
                    )
                    
                    QuickLinkButton(
                        icon: "envelope",
                        title: "Gmail",
                        action: { onNavigate("https://mail.google.com") }
                    )
                    
                    QuickLinkButton(
                        icon: "play.rectangle",
                        title: "YouTube",
                        action: { onNavigate("https://www.youtube.com") }
                    )
                }
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct QuickLinkButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHovering ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    NewTabView { url in
        print("Navigate to: \(url)")
    }
}

