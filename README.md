# StealthTab

A lightweight web browser wrapper for macOS built with SwiftUI and WebKit.

## Features

- 🌐 **WebKit-powered browsing** - Uses the same engine as Safari
- 🔍 **Smart URL bar** - Enter URLs or search directly with Google
- ⬅️➡️ **Navigation controls** - Back, forward, reload, and stop loading
- 🖥️ **Desktop rendering** - Uses a desktop Safari-style User-Agent
- 🕶️ **Stealth window controls** - Hide the browser from screen capture, adjust transparency, and keep it on top
- 🕘 **Browsing history** - Search, reopen, delete, or clear saved history
- 🎨 **Clean, native UI** - Built with SwiftUI for a modern macOS experience
- ⌨️ **Keyboard shortcuts** - Cmd+T, Cmd+W, Cmd+R, Cmd+[ / Cmd+], Cmd+1-9, and Cmd+Y

## Requirements

- macOS 15.6 or later
- Xcode 17.0 or later

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
| **Clear URL** | Click the X button in the address bar |
| **New Tab** | Click the plus button in the tab bar or press Cmd+T |
| **Close Tab** | Press Cmd+W |
| **Switch Tabs** | Press Cmd+1 through Cmd+9 |
| **Open History** | Press Cmd+Y or use History > Show Full History |
| **Hide from Capture** | Click the eye-slash button in the toolbar |
| **Keep on Top** | Click the pin button in the toolbar |
| **Adjust Transparency** | Drag the transparency slider, or use the compact opacity popover at narrow widths |

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
- ✅ Browsing history with search, grouped dates, deletion, and clear-all
- ✅ Professional UI with hover effects
- ✅ Screen capture hiding, adjustable window transparency, and always-on-top mode

## Future Enhancements

- Bookmarks and favorites
- Download manager
- Private/incognito mode
- Custom search engine options
- Safari extension support
- Session restore

## Contributing

This is a learning project demonstrating modern macOS app development with SwiftUI and WebKit.

## License

See LICENSE file for details.
