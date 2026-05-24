# StealthTab Code Organization

This document explains how the current StealthTab codebase is organized and how state moves between SwiftUI, WebKit, AppKit, and persistence.

## Architecture

StealthTab uses a compact MVVM structure:

```
SwiftUI Views
    ↓ observe / call actions
BrowserViewModel + HistoryManager
    ↓ manage
Tab + HistoryItem models
    ↓ bridge
WKWebView and NSWindow
```

The app is intentionally small, so most UI composition lives in `ContentView.swift` and related view files rather than a deep module hierarchy.

## File Map

```
StealthTab/StealthTab/
├── App/
│   └── StealthTabApp.swift
├── Models/
│   ├── Tab.swift
│   └── HistoryItem.swift
├── ViewModels/
│   ├── BrowserViewModel.swift
│   └── HistoryManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── TabBarView.swift
│   ├── NewTabView.swift
│   ├── HistoryView.swift
│   └── WebView.swift
└── Utilities/
    ├── BrowserConfig.swift
    ├── GlobalHotKeyManager.swift
    └── Utils.swift
```

## App Entry

`StealthTabApp.swift` defines the `@main` app, owns the shared `BrowserViewModel`, and creates the browser window through an AppKit `NSPanel`.

It also:

- Uses `AppDelegate` to create and show a reusable `StealthPanelController`.
- Hosts `ContentView` in an `NSHostingView` inside a custom `StealthPanel`.
- Creates the panel as non-activating and floating so pinned mode has the best chance of staying visible across macOS full-screen Spaces.
- Switches to accessory activation policy while pinned, then restores regular app behavior when unpinned.
- Replaces the default New command so menu commands can create tabs through the shared view model.
- Adds a History menu with `Show Full History` and `Clear History...`.

## Models

### Tab

`Tab` is an `ObservableObject` representing one browser tab.

It tracks:

- `title`
- `urlString`
- `isLoading`
- `canGoBack`
- `canGoForward`
- `isNewTab`
- The tab's retained `WKWebView`

Keeping the `WKWebView` on the tab is what lets the app switch tabs without reloading pages.

### HistoryItem

`HistoryItem` is a small `Codable` model with `id`, `url`, `title`, and `visitDate`. `HistoryManager` encodes these items into `UserDefaults`.

## View Models

### BrowserViewModel

`BrowserViewModel` is the main state owner. It is isolated to the main actor because it drives SwiftUI and AppKit objects.

It owns:

- The tab list and active tab id.
- URL bar text.
- History sheet visibility.
- A `HistoryManager`.
- Window settings for screen-capture hiding, opacity, and always-on-top mode.

Core responsibilities:

- Create, close, and switch tabs.
- Drive back, forward, reload, stop, and URL loading.
- Convert user input into URLs through `Utils.processInput`.
- Sync the active tab's URL into the URL bar.
- Add loaded pages to history.
- Attach to the real `NSWindow` and apply window-level privacy settings.

Window settings are persisted with `UserDefaults`:

- `isHiddenFromScreenCapture`
- `windowOpacity`
- `staysOnTop`

When a setting changes, `applyWindowSettings()` updates the live window:

- `window.sharingType = .none` hides it from screen sharing/capture APIs that respect AppKit sharing type.
- `window.level = .screenSaver` while pinned, then restores the original level when unpinned.
- `window.collectionBehavior` adds `.canJoinAllSpaces`, `.fullScreenAuxiliary`, `.stationary`, and `.ignoresCycle` while pinned, so it can follow full-screen Spaces.
- `NSApp.setActivationPolicy` uses accessory mode while pinned to behave more like an overlay utility.
- Space-change and app-deactivation notifications re-order the pinned panel after macOS moves between desktops.
- `window.alphaValue` controls transparency.
- `window.backgroundColor` and `window.isOpaque` are adjusted for transparent states.
- Global opacity hotkeys call `cycleWindowOpacityPreset()` without requiring the app to be active.

### HistoryManager

`HistoryManager` owns browsing history and persists it in `UserDefaults` under `BrowsingHistory`.

It:

- Adds successful page visits.
- Skips empty URLs and `about:blank`.
- Avoids adding the exact same URL twice within five seconds.
- Keeps the newest 1,000 items.
- Searches by lowercased title or URL.
- Deletes individual entries or clears all history.

## Views

### ContentView

`ContentView` receives the shared `BrowserViewModel` and lays out the main browser:

```
TabBarView
Divider
BrowserToolbar
Divider
NewTabView or BrowserWebView
```

It also:

- Handles keyboard shortcuts:
  - Cmd+T: new tab
  - Cmd+W: close tab
  - Cmd+R: reload/stop
  - Cmd+[ and Cmd+]: back/forward
  - Cmd+1 through Cmd+9: switch tabs
- Shows `HistoryView` as a sheet.
- Provides `WindowAccessor`, an `NSViewRepresentable`, to resolve the containing `NSWindow`.

### BrowserToolbar

`BrowserToolbar` contains:

- Back, forward, and reload/stop buttons.
- The URL bar.
- Screen-capture visibility toggle.
- Always-on-top toggle.
- Opacity control.

The opacity control uses an explicit toolbar-width breakpoint:

- At `560pt` and wider, it shows the full slider.
- Below `560pt`, it shows a compact icon button that opens the slider in a popover.

This keeps the window narrow without permanently hiding the full control on wider layouts.

### TabBarView

`TabBarView` displays all open tabs in a horizontal scroll view and provides the plus button for new tabs. `TabItem` renders each tab with its title, loading indicator, active state, hover state, and close button.

### NewTabView

`NewTabView` is shown when the active tab has not navigated yet. It provides a search/URL field plus quick links for Google, News, Gmail, and YouTube.

### HistoryView

`HistoryView` shows saved history in a sheet. It includes:

- Search by title or URL.
- Grouping by Today, Yesterday, This Week, This Month, or month.
- Row tap to reopen a URL.
- Per-row delete on hover.
- Clear-all with confirmation.

### WebView

`WebView` bridges `WKWebView` into SwiftUI with `NSViewRepresentable`.

It:

- Reuses the tab's existing `WKWebView` when available.
- Creates a configured `WKWebView` for new navigated tabs.
- Uses the default website data store.
- Enables JavaScript.
- Enables back/forward swipe gestures.
- Applies the desktop Safari-style user agent from `BrowserConfig`.
- Observes URL, title, loading, back, and forward state.
- Calls back to the view model when a page finishes loading so history can be recorded.

## Utilities

### BrowserConfig

`BrowserConfig` centralizes constants:

- Home URL and search URL.
- Desktop user agent.
- Window minimums: `360` width, `600` height.
- Minimum opacity: `0.25`.
- Keyboard opacity presets: `0.25`, `0.5`, and `1.0`.
- Toolbar, URL bar, and button sizing.

### GlobalHotKeyManager

`GlobalHotKeyManager` registers Carbon global hotkeys for opacity control:

- Control+Option+Command+Down cycles to the next opacity preset.
- Control+Option+Command+Up cycles to the next opacity preset.

The hotkey callback hops back to the main actor before mutating `BrowserViewModel`.

### Utils

`Utils.processInput(_:)` converts address bar text into a navigable URL string.

Rules:

- Existing `http://` and `https://` URLs are used as-is.
- Inputs that look like URLs get `https://` prepended.
- Search-like inputs become Google search URLs.
- URL detection includes localhost, IPv4 addresses, common TLDs, and simple domain patterns.

## Data Flow

### Opening a URL

```
User submits URL bar
    ↓
BrowserViewModel.loadURL()
    ↓
Utils.processInput()
    ↓
Active Tab updates urlString and isNewTab
    ↓
BrowserWebView creates or reuses WKWebView
    ↓
WKWebView loads URLRequest
```

### WebKit State Updates

```
WKWebView changes URL/title/loading/navigation state
    ↓
WebView.Coordinator KVO or delegate callback
    ↓
Tab published properties update
    ↓
SwiftUI refreshes tab title, buttons, URL bar, and loading icon
```

### History

```
WKWebView finishes loading
    ↓
WebView didFinish callback passes URL/title
    ↓
BrowserViewModel.addToHistory()
    ↓
HistoryManager stores newest item
    ↓
HistoryView can search, group, open, or delete it
```

### Window Settings

```
ContentView resolves NSWindow
    ↓
BrowserViewModel.attachWindow()
    ↓
User toggles toolbar control or adjusts opacity
    ↓
UserDefaults updates
    ↓
NSWindow sharingType, level, collection behavior, alpha, opacity, and background update
```

## Current Feature Surface

- Multi-tab browsing with retained `WKWebView` instances.
- New tab screen with quick links.
- Smart URL/search handling.
- Back, forward, reload, and stop.
- Keyboard shortcuts for common tab and navigation actions.
- Searchable browsing history with persistence.
- Screen-capture hiding through `NSWindow.SharingType.none`.
- Adjustable window transparency.
- Always-on-top mode.
- Compact opacity popover for narrow windows.

## Extension Points

Good next additions include:

- Bookmarks/favorites manager.
- Private browsing mode with a non-persistent `WKWebsiteDataStore`.
- Download handling with `WKDownloadDelegate`.
- Session restore for tabs across launches.
- Settings UI for home page, search engine, and default stealth options.

## Notes

- SwiftUI view state is kept local with `@State`.
- Shared app state lives in `BrowserViewModel` or `HistoryManager`.
- UI-observed model state uses `@Published`.
- WebKit delegate and KVO callbacks hop back to the main actor before mutating tab state.
- New source files are picked up through Xcode's file synchronization; manual project file edits are not normally needed.

---

**Last Updated**: May 22, 2026
**Version**: 1.1.0
