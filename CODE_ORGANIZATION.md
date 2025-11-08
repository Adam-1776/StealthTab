# StealthTab Code Organization

This document provides a detailed explanation of the StealthTab browser's code structure, architecture, and implementation.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Design Patterns](#design-patterns)
- [File Structure](#file-structure)
- [Detailed Component Breakdown](#detailed-component-breakdown)
- [Data Flow](#data-flow)
- [Key Implementation Details](#key-implementation-details)

---

## Architecture Overview

StealthTab follows the **MVVM (Model-View-ViewModel)** architecture pattern, which provides clear separation of concerns:

```
┌─────────────────┐
│  ContentView    │  ← View Layer (UI)
│  (SwiftUI)      │
└────────┬────────┘
         │ Bindings
         ↓
┌─────────────────┐
│ BrowserViewModel│  ← ViewModel Layer (Logic & State)
│  (@Published)   │
└────────┬────────┘
         │ Controls
         ↓
┌─────────────────┐
│    WebView      │  ← Model/View Layer (WebKit Wrapper)
│  (WKWebView)    │
└─────────────────┘
         ↕
┌─────────────────┐
│ BrowserConfig   │  ← Configuration Layer (Constants)
└─────────────────┘
```

---

## Design Patterns

### 1. **MVVM (Model-View-ViewModel)**
- **View**: `ContentView.swift` and its sub-components
- **ViewModel**: `BrowserViewModel.swift`
- **Model**: `WebView.swift` (wraps WKWebView)

### 2. **Observable Pattern**
- Uses `@Published` properties in `BrowserViewModel`
- SwiftUI automatically observes changes and updates the UI

### 3. **Coordinator Pattern**
- `WebView.Coordinator` handles WebKit navigation delegate callbacks
- Bridges between WKWebView and SwiftUI

### 4. **Dependency Injection**
- `BrowserViewModel` is injected into view components via `@ObservedObject`
- Allows for testability and flexibility

### 5. **Single Responsibility Principle**
- Each file has one clear purpose
- UI components are small and focused

---

## File Structure

```
StealthTab/
├── StealthTabApp.swift         (App Entry Point)
├── ContentView.swift           (Main UI Components)
├── BrowserViewModel.swift      (State Management)
├── WebView.swift              (WebKit Wrapper)
└── BrowserConfig.swift        (Configuration)
```

---

## Detailed Component Breakdown

### 1. StealthTabApp.swift

**Purpose**: Application entry point and window configuration.

**Key Components**:

```swift
@main
struct StealthTabApp: App
```

**Responsibilities**:
- Define the app's main entry point with `@main`
- Configure the window style (`.hiddenTitleBar`)
- Set up custom keyboard shortcuts and commands
- Initialize the main `WindowGroup` with `ContentView`

**Key Features**:
- **Window Style**: Uses `.hiddenTitleBar` to create a modern, streamlined UI without the standard macOS title bar
- **Command Groups**: Defines custom menu commands (e.g., Cmd+T for new tab - placeholder for future feature)

---

### 2. BrowserConfig.swift

**Purpose**: Centralized configuration and constants.

**Structure**:

```swift
@MainActor
struct BrowserConfig
```

**Configuration Categories**:

#### URLs
- `defaultHomeURL`: Default home page (Google)
- `searchEngineURL`: Search engine query template

#### User Agent
- `desktopUserAgent`: User-Agent string to identify as Safari on macOS
  - Ensures websites serve desktop versions
  - Format matches Safari 17.0 on macOS

#### Window Settings
- `minimumWindowWidth`: 800px minimum width
- `minimumWindowHeight`: 600px minimum height

#### UI Settings
- `toolbarSpacing`: 12px spacing between toolbar items
- `toolbarHorizontalPadding`: 12px horizontal padding
- `toolbarVerticalPadding`: 8px vertical padding
- `urlBarCornerRadius`: 8px rounded corners
- `urlBarHorizontalPadding`: 12px URL bar padding
- `urlBarVerticalPadding`: 6px URL bar padding

#### Button Settings
- `buttonSize`: 28px button dimensions
- `buttonIconSize`: 14px icon size for toolbar buttons
- `urlBarIconSize`: 12px icon size for URL bar icons

**Design Notes**:
- Marked with `@MainActor` for thread-safe access from UI components
- All properties are `static let` for compile-time constants
- Easy to modify design system in one place

---

### 3. BrowserViewModel.swift

**Purpose**: State management and business logic for the browser.

**Structure**:

```swift
@MainActor
class BrowserViewModel: ObservableObject
```

**Published Properties** (Observable State):

| Property | Type | Purpose |
|----------|------|---------|
| `urlString` | `String` | Current page URL (source of truth) |
| `urlInput` | `String` | URL bar text (user input) |
| `canGoBack` | `Bool` | Enable/disable back button |
| `canGoForward` | `Bool` | Enable/disable forward button |
| `isLoading` | `Bool` | Loading state indicator |
| `pageTitle` | `String` | Current page title |
| `webView` | `WKWebView?` | Reference to the web view instance |

#### Initialization

```swift
init()
```
- Initializes with default home URL
- Sets both `urlString` and `urlInput` to Google

#### Navigation Methods

**`goBack()`**
- Calls `webView?.goBack()`
- Navigates to previous page in history
- Button disabled when `canGoBack` is false

**`goForward()`**
- Calls `webView?.goForward()`
- Navigates to next page in history
- Button disabled when `canGoForward` is false

**`reload()`**
- Smart reload/stop functionality
- If loading: stops the current navigation
- If not loading: reloads the current page

**`goHome()`**
- Navigates to `BrowserConfig.defaultHomeURL`
- Resets to Google homepage

**`clearURLInput()`**
- Clears the URL input field
- Used by the X button in URL bar

#### URL Loading Logic

**`loadURL(_ input: String)`**

This is the core navigation method with smart URL handling:

**Step 1: Trim whitespace**
```swift
var urlToLoad = input.trimmingCharacters(in: .whitespaces)
```

**Step 2: Detect URL vs Search Query**
```swift
if !urlToLoad.contains(".") || !urlToLoad.contains("://") {
    // It's a search query - use Google search
    urlToLoad = constructSearchURL(query: urlToLoad)
}
```

Logic:
- If input has no dot (.) or protocol (://), treat as search
- Example: "cats" → Google search for "cats"

**Step 3: Add HTTPS if needed**
```swift
else if !urlToLoad.hasPrefix("http://") && !urlToLoad.hasPrefix("https://") {
    urlToLoad = "https://" + urlToLoad
}
```

Logic:
- If it looks like a URL but lacks protocol, add `https://`
- Example: "apple.com" → "https://apple.com"

**Step 4: Load the URL**
```swift
if let url = URL(string: urlToLoad) {
    webView?.load(URLRequest(url: url))
    urlString = urlToLoad
}
```

**`updateURLInput(from urlString: String)`**
- Syncs URL bar text with actual current URL
- Called when page navigation completes

**`constructSearchURL(query: String) -> String`** (Private)
- URL-encodes the search query
- Constructs Google search URL
- Example: "hello world" → "https://www.google.com/search?q=hello%20world"

**Design Notes**:
- `@MainActor` ensures all UI updates happen on main thread
- `ObservableObject` enables SwiftUI to observe changes
- Holds reference to `WKWebView` to control navigation
- Separates state (`urlString`) from user input (`urlInput`)

---

### 4. WebView.swift

**Purpose**: SwiftUI wrapper for WKWebView (WebKit engine).

**Structure**:

```swift
struct WebView: NSViewRepresentable
```

**Binding Properties** (Two-way Data Flow):

| Property | Type | Direction |
|----------|------|-----------|
| `urlString` | `Binding<String>` | WebView → ViewModel |
| `canGoBack` | `Binding<Bool>` | WebView → ViewModel |
| `canGoForward` | `Binding<Bool>` | WebView → ViewModel |
| `isLoading` | `Binding<Bool>` | WebView → ViewModel |
| `pageTitle` | `Binding<String>` | WebView → ViewModel |
| `webView` | `Binding<WKWebView?>` | WebView → ViewModel |

#### NSViewRepresentable Protocol Methods

**`makeCoordinator() -> Coordinator`**
- Creates the coordinator that handles WebKit delegate callbacks
- Called once when the view is first created

**`makeNSView(context: Context) -> WKWebView`**

This method sets up the WKWebView:

**Step 1: Create Configuration**
```swift
let configuration = WKWebViewConfiguration()
configuration.websiteDataStore = .default()
```
- Uses default data store (cookies, cache, etc.)

**Step 2: Set JavaScript Preferences**
```swift
let preferences = WKWebpagePreferences()
preferences.allowsContentJavaScript = true
configuration.defaultWebpagePreferences = preferences
```
- Explicitly enables JavaScript execution
- Required for modern web applications

**Step 3: Initialize WKWebView**
```swift
let webView = WKWebView(frame: .zero, configuration: configuration)
webView.navigationDelegate = context.coordinator
webView.allowsBackForwardNavigationGestures = true
```
- Sets navigation delegate to coordinator
- Enables trackpad swipe gestures for navigation

**Step 4: Set Desktop User-Agent**
```swift
webView.customUserAgent = BrowserConfig.desktopUserAgent
```
- Identifies as Safari on macOS
- Ensures websites serve desktop layouts
- Critical for proper rendering (e.g., Google's centered logo)

**Step 5: Load Initial URL**
```swift
if let url = URL(string: urlString) {
    webView.load(URLRequest(url: url))
}
```

**Step 6: Store Reference**
```swift
DispatchQueue.main.async {
    self.webView = webView
}
```
- Async to avoid SwiftUI state mutation during view update
- Allows ViewModel to control the web view

**`updateNSView(_ nsView: WKWebView, context: Context)`**
- Called when SwiftUI state changes
- Currently empty as updates are handled by coordinator

#### Coordinator Class

**Purpose**: Bridge between WKWebView delegate and SwiftUI bindings.

```swift
class Coordinator: NSObject, WKNavigationDelegate
```

**`init(_ parent: WebView)`**
- Stores reference to parent WebView
- Allows access to bindings

**WKNavigationDelegate Methods**:

**`webView(_:didStartProvisionalNavigation:)`**
```swift
parent.isLoading = true
```
- Called when navigation starts
- Updates loading indicator

**`webView(_:didFinish:)`**
```swift
parent.isLoading = false
parent.canGoBack = webView.canGoBack
parent.canGoForward = webView.canGoForward

if let url = webView.url?.absoluteString {
    parent.urlString = url
}

if let title = webView.title {
    parent.pageTitle = title
}
```
- Called when page finishes loading
- Updates all navigation state
- Syncs URL bar with actual current URL
- Updates page title

**`webView(_:didFail:withError:)`**
```swift
parent.isLoading = false
print("Navigation failed: \(error.localizedDescription)")
```
- Called when navigation fails
- Stops loading indicator
- Logs error

**`webView(_:didFailProvisionalNavigation:withError:)`**
```swift
parent.isLoading = false
print("Provisional navigation failed: \(error.localizedDescription)")
```
- Called when provisional navigation fails (e.g., DNS error)
- Stops loading indicator
- Logs error

**`webView(_:decidePolicyFor:decisionHandler:)`**
```swift
decisionHandler(.allow)
```
- Called before each navigation
- Can block or allow navigation
- Currently allows all navigation

**Design Notes**:
- `NSViewRepresentable` bridges AppKit (WKWebView) to SwiftUI
- Coordinator pattern handles delegate callbacks
- Bindings create reactive data flow
- Proper User-Agent ensures correct rendering

---

### 5. ContentView.swift

**Purpose**: Main UI composition and view components.

**Structure**: Hierarchical view composition with small, reusable components.

#### Main View: ContentView

```swift
struct ContentView: View
```

**State Management**:
```swift
@StateObject private var viewModel = BrowserViewModel()
```
- Creates and owns the view model
- `@StateObject` ensures single instance for view lifetime

**Layout Structure**:
```swift
VStack(spacing: 0) {
    BrowserToolbar(viewModel: viewModel)
    Divider()
    BrowserWebView(viewModel: viewModel)
}
.frame(minWidth: 800, minHeight: 600)
.onChange(of: viewModel.urlString) { oldValue, newValue in
    viewModel.updateURLInput(from: newValue)
}
```

**Key Features**:
- Zero spacing VStack for seamless layout
- Divider separates toolbar from content
- Minimum window size enforced
- URL sync via `onChange`

---

#### BrowserToolbar

```swift
struct BrowserToolbar: View
```

**Purpose**: Container for all toolbar elements.

**Layout**:
```swift
HStack(spacing: BrowserConfig.toolbarSpacing) {
    NavigationButtons(viewModel: viewModel)
    URLBar(viewModel: viewModel)
    HomeButton(viewModel: viewModel)
}
.padding(.horizontal, BrowserConfig.toolbarHorizontalPadding)
.padding(.vertical, BrowserConfig.toolbarVerticalPadding)
.background(Color(nsColor: .windowBackgroundColor))
```

**Components**:
1. Navigation buttons (left)
2. URL bar (center, flexible)
3. Home button (right)

**Design**:
- Uses system background color for native look
- All spacing from `BrowserConfig`

---

#### NavigationButtons

```swift
struct NavigationButtons: View
```

**Purpose**: Groups back, forward, and reload buttons.

**Components**:

**Back Button**:
- Icon: `chevron.left`
- Action: `viewModel.goBack()`
- Enabled: `viewModel.canGoBack`
- Tooltip: "Go Back"

**Forward Button**:
- Icon: `chevron.right`
- Action: `viewModel.goForward()`
- Enabled: `viewModel.canGoForward`
- Tooltip: "Go Forward"

**Reload/Stop Button**:
- Icon: Dynamic - `xmark` when loading, `arrow.clockwise` otherwise
- Action: `viewModel.reload()` (smart reload/stop)
- Always enabled
- Tooltip: Dynamic - "Stop Loading" or "Reload"

---

#### NavigationButton

```swift
struct NavigationButton: View
```

**Purpose**: Reusable button component for navigation actions.

**Parameters**:
- `iconName`: SF Symbol name
- `action`: Closure to execute
- `isEnabled`: Enable/disable state
- `tooltip`: Help text on hover

**Implementation**:
```swift
Button(action: action) {
    Image(systemName: iconName)
        .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
        .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
}
.buttonStyle(.plain)
.disabled(!isEnabled)
.opacity(isEnabled ? 1.0 : 0.3)
.help(tooltip)
```

**Features**:
- Consistent sizing from config
- Plain style (no standard button chrome)
- Visual disabled state (30% opacity)
- Hover tooltips via `.help()`

---

#### URLBar

```swift
struct URLBar: View
```

**Purpose**: Address bar with icon, text field, and clear button.

**Layout**:
```swift
HStack(spacing: 8) {
    URLBarIcon(isLoading: viewModel.isLoading)
    URLTextField(viewModel: viewModel)
    if !viewModel.urlInput.isEmpty {
        ClearButton(action: viewModel.clearURLInput)
    }
}
.padding(.horizontal, BrowserConfig.urlBarHorizontalPadding)
.padding(.vertical, BrowserConfig.urlBarVerticalPadding)
.background(Color(nsColor: .controlBackgroundColor))
.cornerRadius(BrowserConfig.urlBarCornerRadius)
```

**Features**:
- Flexible width (fills available space)
- Rounded corners for modern look
- Conditional clear button (only when text present)
- System control background color

---

#### URLBarIcon

```swift
struct URLBarIcon: View
```

**Purpose**: Dynamic icon showing loading or security state.

**Logic**:
```swift
Image(systemName: isLoading ? "arrow.2.circlepath" : "lock.fill")
    .font(.system(size: BrowserConfig.urlBarIconSize))
    .foregroundColor(isLoading ? .blue : .green)
    .opacity(isLoading ? 0.6 : 0.8)
```

**States**:
- **Loading**: Blue animated arrows
- **Loaded**: Green lock icon (HTTPS indicator)

---

#### URLTextField

```swift
struct URLTextField: View
```

**Purpose**: Text input for URLs and search queries.

**Implementation**:
```swift
TextField("Enter URL or search...", text: $viewModel.urlInput)
    .textFieldStyle(.plain)
    .font(.system(size: 13))
    .onSubmit {
        viewModel.loadURL(viewModel.urlInput)
    }
```

**Features**:
- Two-way binding to `urlInput`
- Plain style (no border/background)
- Submit on Enter key
- 13pt system font

---

#### ClearButton

```swift
struct ClearButton: View
```

**Purpose**: X button to clear URL input.

**Implementation**:
```swift
Button(action: action) {
    Image(systemName: "xmark.circle.fill")
        .font(.system(size: BrowserConfig.urlBarIconSize))
        .foregroundColor(.secondary)
}
.buttonStyle(.plain)
```

**Features**:
- Secondary color (gray)
- Plain button style
- Compact size

---

#### HomeButton

```swift
struct HomeButton: View
```

**Purpose**: Quick navigation to home page.

**Implementation**:
```swift
Button(action: viewModel.goHome) {
    Image(systemName: "house.fill")
        .font(.system(size: BrowserConfig.buttonIconSize, weight: .medium))
        .frame(width: BrowserConfig.buttonSize, height: BrowserConfig.buttonSize)
}
.buttonStyle(.plain)
.help("Home")
```

**Features**:
- House icon
- Always enabled
- Tooltip on hover

---

#### BrowserWebView

```swift
struct BrowserWebView: View
```

**Purpose**: Container for the WebView component.

**Implementation**:
```swift
WebView(
    urlString: $viewModel.urlString,
    canGoBack: $viewModel.canGoBack,
    canGoForward: $viewModel.canGoForward,
    isLoading: $viewModel.isLoading,
    pageTitle: $viewModel.pageTitle,
    webView: $viewModel.webView
)
```

**Features**:
- Passes all bindings from ViewModel to WebView
- Fills remaining space in VStack

---

## Data Flow

### 1. User Enters URL

```
User Types → URLTextField → viewModel.urlInput
User Presses Enter → onSubmit → viewModel.loadURL()
loadURL() → Processes URL/Search → webView?.load()
```

### 2. Page Loads

```
WKWebView Navigation Starts
    ↓
Coordinator.didStartProvisionalNavigation
    ↓
parent.isLoading = true
    ↓
SwiftUI Updates URLBarIcon (shows loading)
    ↓
WKWebView Navigation Completes
    ↓
Coordinator.didFinish
    ↓
Updates: urlString, canGoBack, canGoForward, pageTitle, isLoading
    ↓
SwiftUI Updates UI (URL bar, buttons, icon)
```

### 3. User Clicks Back Button

```
User Clicks Back
    ↓
NavigationButton.action()
    ↓
viewModel.goBack()
    ↓
webView?.goBack()
    ↓
(Triggers Page Load Flow Above)
```

### 4. URL Sync

```
Page Navigation Completes
    ↓
Coordinator updates urlString
    ↓
ContentView.onChange(of: urlString)
    ↓
viewModel.updateURLInput()
    ↓
URL bar shows current URL
```

---

## Key Implementation Details

### Thread Safety

**Main Actor Isolation**:
```swift
@MainActor
class BrowserViewModel: ObservableObject
```

```swift
@MainActor
struct BrowserConfig
```

- All UI-related code runs on main thread
- Prevents race conditions
- SwiftUI requirement

### Reactive Updates

**Published Properties**:
```swift
@Published var urlString: String
@Published var isLoading: Bool
```

- Automatically notifies SwiftUI of changes
- UI updates automatically
- No manual refresh needed

### Binding Flow

```swift
// ViewModel owns the state
@Published var urlString: String

// View creates binding
WebView(urlString: $viewModel.urlString, ...)

// WebView receives binding
@Binding var urlString: String

// WebView updates it
parent.urlString = newValue

// SwiftUI propagates change back to ViewModel
// UI automatically updates
```

### User-Agent Importance

Without the custom User-Agent:
- Websites detect mobile browser
- Serve mobile layouts
- Google logo appears at top (mobile style)

With desktop User-Agent:
- Websites detect desktop Safari
- Serve desktop layouts
- Google logo centered (desktop style)

### Smart URL Handling

**Examples**:

| Input | Detection | Result |
|-------|-----------|--------|
| `apple.com` | Has dot, no protocol | `https://apple.com` |
| `cats` | No dot | Google search |
| `how to cook` | No dot | Google search |
| `https://github.com` | Has protocol | Load as-is |
| `localhost:3000` | Has dot | `https://localhost:3000` |

### Error Handling

**Navigation Failures**:
- Logged to console
- Loading state reset
- User can try again

**URL Parsing Failures**:
- Invalid URLs ignored
- No navigation occurs
- Current page remains

### Memory Management

**WebView Reference**:
```swift
DispatchQueue.main.async {
    self.webView = webView
}
```

- Async to avoid SwiftUI state mutation warnings
- Weak reference not needed (lifecycle tied to view)

### Configuration Benefits

Centralized constants enable:
- Easy theme changes
- Consistent spacing
- Quick prototyping
- Design system enforcement

**Example Change**:
```swift
// Change button size across entire app
static let buttonSize: CGFloat = 32 // was 28
```

### Component Reusability

**NavigationButton** used for:
- Back button
- Forward button
- Reload button

**Same code, different parameters** - DRY principle.

---

## Future Extension Points

### Multiple Tabs
- Create `Tab` model
- Add `@Published var tabs: [Tab]` to ViewModel
- Create `TabBar` component in ContentView
- Each tab has its own `WKWebView`

### Bookmarks
- Create `Bookmark` model
- Add `BookmarksManager` class
- Add toolbar button and sidebar
- Persist to UserDefaults or file

### History
- Create `HistoryItem` model
- Log in `Coordinator.didFinish`
- Add history view
- Add clear history function

### Downloads
- Implement `WKDownloadDelegate`
- Show download progress
- Manage download location

### Settings
- Create `Settings` view
- Add preferences: home page, search engine, etc.
- Persist to UserDefaults

---

## Conclusion

StealthTab demonstrates:
- ✅ Clean architecture with MVVM
- ✅ Proper separation of concerns
- ✅ Reactive programming with Combine
- ✅ Reusable UI components
- ✅ Centralized configuration
- ✅ Thread-safe design
- ✅ Professional code organization

The codebase is maintainable, testable, and ready for future enhancements.

