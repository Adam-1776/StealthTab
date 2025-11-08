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

## Quick Start

1. Open `StealthTab/StealthTab.xcodeproj` in Xcode
2. Select your target device/Mac
3. Press **Cmd+R** to build and run

That's it! The browser will launch with Google as the home page.

## Usage

| Action | How To |
|--------|--------|
| **Navigate** | Enter a URL or search term in the address bar and press Enter |
| **Go Back/Forward** | Click the chevron buttons or use trackpad swipe gestures |
| **Reload/Stop** | Click the refresh button (becomes a stop button while loading) |
| **Go Home** | Click the house icon to return to Google |
| **Clear URL** | Click the X button in the address bar |

## Documentation

📖 **For detailed technical documentation**, including architecture, code organization, and implementation details, see **[CODE_ORGANIZATION.md](CODE_ORGANIZATION.md)**.

## Future Enhancements

- Multiple tab support
- Bookmarks and favorites
- Browsing history
- Download manager
- Private/incognito mode
- Custom search engine options
- Safari extension support

## Contributing

This is a learning project demonstrating modern macOS app development with SwiftUI and WebKit.

## License

See LICENSE file for details.