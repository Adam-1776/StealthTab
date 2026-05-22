# StealthTab

A lightweight web browser wrapper for macOS built with SwiftUI and WebKit.

## Features

- 🌐 **WebKit-powered browsing** - Uses the same engine as Safari
- 🔍 **Smart URL bar** - Enter URLs or search directly with Google
- ⬅️➡️ **Navigation controls** - Back, forward, reload, and home buttons
- 🔒 **Secure browsing** - HTTPS indicator in URL bar
- 🕶️ **Stealth window controls** - Hide the browser from screen capture, adjust transparency, and keep it on top
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
| **Hide from Capture** | Click the eye-slash button in the toolbar |
| **Keep on Top** | Click the pin button in the toolbar |
| **Adjust Transparency** | Drag the transparency slider in the toolbar |

## Documentation

📖 **Technical Documentation:**
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project organization and architecture overview
- **[CODE_ORGANIZATION.md](CODE_ORGANIZATION.md)** - Detailed code implementation and design patterns

## Features Implemented

- ✅ Multiple tab support with tab bar
- ✅ New tab screen with quick links
- ✅ Smart URL detection (URLs vs search queries)
- ✅ Keyboard shortcuts (Cmd+T, Cmd+W, Cmd+1-9, etc.)
- ✅ Tab persistence (no reload on switch)
- ✅ Professional UI with hover effects
- ✅ Screen capture hiding, adjustable window transparency, and always-on-top mode

## Future Enhancements

- Bookmarks and favorites
- Browsing history
- Download manager
- Private/incognito mode
- Custom search engine options
- Safari extension support
- Session restore

## Contributing

This is a learning project demonstrating modern macOS app development with SwiftUI and WebKit.

## License

See LICENSE file for details.
