# StealthTab

A lightweight web browser wrapper for macOS built with SwiftUI and WebKit.

## Features

- 🌐 **WebKit-powered browsing** - Uses the same engine as Safari
- 🔍 **Smart URL bar** - Enter URLs or search directly with Google
- ⬅️➡️ **Navigation controls** - Back, forward, reload, and home buttons  
- 🔒 **Secure browsing** - HTTPS indicator in URL bar
- 🎨 **Clean, native UI** - Built with SwiftUI for a modern macOS experience
- ⌨️ **Keyboard shortcuts** - Cmd+T for new tab (ready for future multi-tab support)

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later

## Building & Running

1. Open `StealthTab/StealthTab.xcodeproj` in Xcode
2. Select your target device/Mac
3. Press Cmd+R to build and run

## Usage

- **Navigate**: Enter a URL or search term in the address bar and press Enter
- **Go Back/Forward**: Click the chevron buttons or use trackpad gestures
- **Reload**: Click the refresh button (becomes a stop button while loading)
- **Home**: Click the house icon to return to Google
- **Clear URL**: Click the X button in the address bar

## Architecture

The app consists of two main components:

1. **StealthTabApp.swift** - Main app entry point with window configuration
2. **ContentView.swift** - Browser UI with toolbar, controls, and WebKit integration

## Future Enhancements

- Multiple tab support
- Bookmarks
- History
- Download manager
- Privacy/incognito mode
- Custom search engine options
- Extension support

## License

See LICENSE file for details.