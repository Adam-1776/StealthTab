# StealthTab Project Structure

This document outlines the organization and architecture of the StealthTab browser codebase.

## 📁 Directory Structure

```
StealthTab/
├── App/
│   └── StealthTabApp.swift          # Application entry point
│
├── Models/
│   └── Tab.swift                    # Tab data model
│
├── ViewModels/
│   └── BrowserViewModel.swift       # Browser state & business logic
│
├── Views/
│   ├── ContentView.swift            # Main browser UI container
│   ├── TabBarView.swift             # Tab bar with tab items
│   ├── NewTabView.swift             # New tab screen
│   └── WebView.swift                # WKWebView wrapper
│
├── Utilities/
│   ├── BrowserConfig.swift          # Configuration constants
│   └── Utils.swift                  # Helper functions (URL parsing, etc.)
│
└── Assets.xcassets/                 # App icons and assets
```

## 🏗️ Architecture Overview

### MVVM Pattern

StealthTab follows the **Model-View-ViewModel** architecture:

```
┌─────────────────────┐
│   Views/            │  ← UI Layer (SwiftUI)
│   - ContentView     │
│   - TabBarView      │
│   - NewTabView      │
│   - WebView         │
└──────────┬──────────┘
           │ Observes
           ↓
┌─────────────────────┐
│   ViewModels/       │  ← Logic Layer
│   - BrowserViewModel│
└──────────┬──────────┘
           │ Manages
           ↓
┌─────────────────────┐
│   Models/           │  ← Data Layer
│   - Tab             │
└─────────────────────┘
           ↕
┌─────────────────────┐
│   Utilities/        │  ← Helper Layer
│   - Utils           │
│   - BrowserConfig   │
└─────────────────────┘
```

## 📂 Layer Descriptions

### 1. App/
**Purpose**: Application lifecycle and configuration
- `StealthTabApp.swift` - Main `@main` entry point, window setup

### 2. Models/
**Purpose**: Data structures representing domain entities
- `Tab.swift` - Represents a browser tab with URL, title, loading state, etc.
- Conforms to `ObservableObject` for SwiftUI reactivity
- Holds reference to WKWebView instance

### 3. ViewModels/
**Purpose**: Business logic and state management
- `BrowserViewModel.swift` - Central state manager for the browser
  - Manages array of tabs
  - Handles tab creation, switching, closing
  - Navigation actions (back, forward, reload)
  - URL input processing
  - Observable by views via `@Published` properties

### 4. Views/
**Purpose**: SwiftUI user interface components

#### ContentView.swift
- Main container view
- Coordinates tab bar, toolbar, and web content
- Handles keyboard shortcuts
- Manages view switching (WebView vs NewTabView)

#### TabBarView.swift
- Horizontal tab bar with scrolling
- Individual tab items with close buttons
- New tab (+) button
- Tab selection and hover effects

#### NewTabView.swift
- Landing page for new tabs
- Search/URL input field
- Quick links to popular sites
- Clean, centered design

#### WebView.swift
- NSViewRepresentable wrapper for WKWebView
- WebKit navigation delegate
- Bridges WebKit callbacks to SwiftUI state

### 5. Utilities/
**Purpose**: Shared helpers and configuration

#### BrowserConfig.swift
- Centralized constants
- URLs (home page, search engine)
- User-Agent string
- UI measurements (sizes, spacing, padding)
- Design tokens

#### Utils.swift
- URL parsing and validation
- Search query detection
- TLD checking
- IP address validation
- Regex pattern matching

### 6. Assets.xcassets/
- App icons
- Accent colors
- Other visual assets

## 🔄 Data Flow

### Tab Creation Flow
```
User Action (Cmd+T or + button)
    ↓
ContentView receives event
    ↓
BrowserViewModel.createNewTab()
    ↓
New Tab model created
    ↓
Added to tabs array
    ↓
SwiftUI updates UI (new tab appears)
```

### Navigation Flow
```
User enters URL in URLBar
    ↓
BrowserViewModel.loadURL(input)
    ↓
Utils.processInput(input) [URL parsing]
    ↓
Tab.isNewTab = false
    ↓
WebView switches from NewTabView
    ↓
WKWebView.load(URLRequest)
    ↓
WebView.Coordinator receives callbacks
    ↓
Tab properties updated (title, loading state, etc.)
    ↓
SwiftUI re-renders affected views
```

## 🎯 Design Principles

### 1. Separation of Concerns
- Each layer has a single, well-defined responsibility
- Views don't contain business logic
- ViewModels don't know about UI implementation
- Models are pure data structures

### 2. Dependency Flow
```
Views → ViewModels → Models
  ↓
Utilities (used by all layers)
```

### 3. Reactive Programming
- Uses Combine framework (`@Published`, `ObservableObject`)
- UI automatically updates when state changes
- No manual view refresh needed

### 4. Reusability
- Small, focused components (TabItem, NavigationButton, etc.)
- Utility functions can be used anywhere
- Configuration centralized in BrowserConfig

### 5. Testability
- ViewModels can be tested without UI
- Utilities are pure functions (easy to unit test)
- Models are simple data structures

## 🚀 Adding New Features

### To add a new View:
1. Create file in `Views/`
2. Import SwiftUI
3. Use MARK comments for organization
4. Pass ViewModel as `@ObservedObject` if needed

### To add new business logic:
1. Add to `BrowserViewModel.swift`
2. Add `@Published` properties for observable state
3. Create public methods for actions
4. Keep private helpers at bottom

### To add new utilities:
1. Add to `Utils.swift` as static methods
2. Or create new file in `Utilities/` if substantial
3. Keep functions pure when possible

### To add new configuration:
1. Add to `BrowserConfig.swift`
2. Use `static let` for constants
3. Group related settings with MARK comments

## 📊 File Statistics

- **Total Swift Files**: 9
- **Lines of Code**: ~1,200
- **Views**: 4 files
- **ViewModels**: 1 file
- **Models**: 1 file
- **Utilities**: 2 files
- **App**: 1 file

## 🔍 Code Conventions

### Naming
- Views: PascalCase, descriptive names (e.g., `TabBarView`)
- ViewModels: Suffix with `ViewModel` (e.g., `BrowserViewModel`)
- Models: Singular nouns (e.g., `Tab`, not `Tabs`)
- Utilities: Descriptive of function (e.g., `Utils`, `BrowserConfig`)

### Organization
- Use `// MARK: -` to separate sections
- Group related code together
- Public members first, private at bottom
- Properties before methods

### State Management
- `@Published` for observable properties
- `@State` for local view state
- `@ObservedObject` for ViewModel references
- `@StateObject` for ViewModel creation

## 📚 Dependencies

- **SwiftUI**: UI framework
- **WebKit**: Web rendering engine
- **Combine**: Reactive programming

## 🎓 Learning Resources

For developers new to this codebase:

1. Start with `StealthTabApp.swift` (entry point)
2. Read `BrowserViewModel.swift` (state management)
3. Explore `ContentView.swift` (main UI)
4. Review `Tab.swift` (data model)
5. Check `Utils.swift` (helper functions)

## 📝 Notes

- Project uses Xcode's automatic file synchronization
- No manual pbxproj updates needed for new files
- Follows Apple's SwiftUI best practices
- Designed for macOS 14.0+

---

**Last Updated**: November 8, 2025
**Version**: 1.0.0

