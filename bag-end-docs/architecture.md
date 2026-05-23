# Bag End — Architecture

## 1. Product definition

**Bag End** is a macOS screenshot shelf. The app captures screenshots with a workflow similar to `Command + Shift + 4`, but instead of saving the screenshot to Desktop, it stores the image in a temporary visual shelf that drops down from the MacBook notch or from the top edge of the active display.

The core user flow:

```text
Hotkey → Select screen region → Capture screenshot → Store in Bag End shelf → Drag screenshot into another app
```

The app should feel like a native macOS utility, not like a large screenshot editor.

## 2. Product principles

Bag End should follow these principles:

1. **Fast capture** — the user should not think about file names, folders, or export dialogs.
2. **Temporary by default** — screenshots are held for short-term use and removed automatically unless pinned.
3. **Drag-first interaction** — every screenshot card should behave like a real draggable file/image.
4. **Desktop stays clean** — screenshots should not pollute Desktop.
5. **Native macOS behavior** — use AppKit, SwiftUI, NSPasteboard, NSItemProvider, and system permissions correctly.
6. **Local-first privacy** — screenshots remain local unless the user explicitly enables export/sync.
7. **Notch-aware, not notch-dependent** — on MacBooks with a notch, the shelf drops from the notch; on other displays, it drops from the top center or menu bar area.

## 3. Recommended stack

Primary stack:

```text
Language: Swift
UI: SwiftUI + AppKit
Capture: ScreenCaptureKit / CoreGraphics / temporary screencapture fallback
Windowing: NSPanel / borderless NSWindow
Storage: FileManager + SQLite
Drag and drop: NSPasteboard + NSItemProvider + file URLs
Settings: SwiftUI Settings scene + UserDefaults
Distribution: notarized DMG first, App Store later if needed
```

Development tools:

```text
Xcode: required for project creation, signing, entitlements, builds, debugging, notarization
VS Code: optional editor for Swift files and Markdown documentation
Git: required
Swift Package Manager: for dependencies
```

## 4. High-level architecture

```text
BagEnd.app
├── AppCore
│   ├── AppState
│   ├── SettingsStore
│   ├── PermissionsManager
│   ├── ShortcutManager
│   └── Logger
│
├── Capture
│   ├── CaptureCoordinator
│   ├── RegionSelectionOverlay
│   ├── ScreenCaptureService
│   ├── ScreenshotPostProcessor
│   └── CaptureResult
│
├── Shelf
│   ├── ShelfWindowController
│   ├── ShelfView
│   ├── ScreenshotCardView
│   ├── NotchPositioningService
│   └── ShelfAnimator
│
├── Storage
│   ├── ScreenshotRepository
│   ├── FileStorageService
│   ├── MetadataStore
│   ├── ThumbnailService
│   └── CleanupScheduler
│
├── DragDrop
│   ├── DragItemProvider
│   ├── PasteboardService
│   ├── FilePromiseService
│   └── DropCompatibility
│
├── MenuBar
│   ├── StatusBarController
│   ├── MenuBarMenu
│   └── PreferencesWindow
│
├── Settings
│   ├── GeneralSettingsView
│   ├── ShortcutSettingsView
│   ├── StorageSettingsView
│   └── PrivacySettingsView
│
└── Shared
    ├── Models
    ├── Extensions
    └── Utilities
```

## 5. Module responsibilities

### 5.1 AppCore

Responsible for application lifecycle, global state, permissions, settings, keyboard shortcuts, and logging.

Key types:

```text
AppState
SettingsStore
PermissionsManager
ShortcutManager
Logger
```

Responsibilities:

- Start menu bar app.
- Register global hotkeys.
- Check Screen Recording permission.
- Open onboarding when permissions are missing.
- Store user preferences.
- Coordinate app-wide events.

### 5.2 Capture

Responsible for screenshot capture.

Initial MVP may use the macOS `screencapture` command as a fallback because it is fast to prototype. The product version should move toward a native capture pipeline.

Capture modes:

```text
Capture Area
Capture Full Screen
Capture Window
Capture to Shelf
Capture to Shelf + Clipboard
```

Recommended pipeline:

```text
User presses hotkey
    ↓
CaptureCoordinator starts region selection
    ↓
RegionSelectionOverlay draws selection rectangle
    ↓
ScreenCaptureService captures selected area
    ↓
ScreenshotPostProcessor normalizes image
    ↓
Storage module persists image
    ↓
Shelf module displays new screenshot
```

The capture module should not know how the shelf UI works. It should return a `CaptureResult`.

Example model:

```swift
struct CaptureResult {
    let id: UUID
    let imageData: Data
    let width: Int
    let height: Int
    let scale: CGFloat
    let capturedAt: Date
    let sourceDisplayID: CGDirectDisplayID?
}
```

### 5.3 Shelf

Responsible for showing screenshots in a floating shelf.

The shelf should be implemented as an AppKit `NSPanel` or borderless `NSWindow` containing SwiftUI content.

Expected behavior:

- Appears after a screenshot is captured.
- Drops down from the notch/top edge.
- Auto-hides after a configurable delay.
- Opens on hotkey.
- Supports hover-to-open if enabled.
- Shows recent screenshots as cards.
- Supports drag-out, delete, pin, copy, save as.

Window behavior:

```text
Window type: NSPanel or borderless NSWindow
Level: floating / statusBar-level equivalent
Activation: preferably non-activating unless interacting with controls
Background: transparent
Content: SwiftUI view embedded in NSHostingView
```

Shelf layout:

```text
┌─────────────────────────────────────────────┐
│ Bag End                                     │
│ [screenshot] [screenshot] [screenshot] [+]  │
│ Clear all       Open settings       Pin mode│
└─────────────────────────────────────────────┘
```

### 5.4 NotchPositioningService

Responsible for calculating shelf position.

Rules:

1. Detect active screen.
2. Use top-center of active screen by default.
3. On MacBook displays with notch-like safe area behavior, position visually under the notch.
4. On external displays, use the top-center of the display.
5. If menu bar is hidden, still position relative to screen top.
6. Support manual override later.

The app must not depend on private notch APIs. The notch behavior should be visual positioning, not true embedding into the notch.

### 5.5 Storage

Responsible for local screenshot persistence.

Recommended storage path:

```text
~/Library/Application Support/Bag End/
├── screenshots/
├── thumbnails/
└── bagend.sqlite
```

MVP may use:

```text
~/Library/Application Support/Bag End/screenshots/
manifest.json
```

Recommended production schema:

```sql
CREATE TABLE screenshots (
    id TEXT PRIMARY KEY,
    file_path TEXT NOT NULL,
    thumbnail_path TEXT,
    created_at TEXT NOT NULL,
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    scale REAL NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    source_display_id TEXT,
    is_pinned INTEGER DEFAULT 0,
    expires_at TEXT,
    last_dragged_at TEXT,
    deleted_at TEXT,
    note TEXT
);
```

Retention policy:

```text
Unpinned screenshots: delete after 24 hours by default
Pinned screenshots: keep until manually deleted
Maximum unpinned item count: 25 by default
```

### 5.6 DragDrop

Responsible for moving screenshots from Bag End into other apps.

Each screenshot card should expose multiple representations:

```text
file URL
PNG data
TIFF/NSImage representation
public.image UTI
file promise if needed later
```

Minimum MVP support:

```text
Drag to Finder
Drag to Telegram/Discord/Slack
Drag to browser upload form
Drag to Preview
Drag to Notes/Notion/Obsidian
Copy image to clipboard
```

This module is critical because the product succeeds only if dragging feels reliable.

### 5.7 MenuBar

Bag End should run primarily as a menu bar app.

Menu bar actions:

```text
Capture Area
Show Shelf
Clear Unpinned Screenshots
Preferences
Quit
```

Dock icon:

- Hidden by default for utility behavior.
- Optional setting to show Dock icon.

### 5.8 Settings

Settings should be simple in the MVP.

Required settings:

```text
Capture Area Hotkey
Toggle Shelf Hotkey
Show shelf after capture
Auto-hide delay
Max unpinned screenshots
Delete unpinned after
Default export format
Copy to clipboard after capture
Launch at login
```

Later settings:

```text
Shelf position
OCR enable/disable
Cloud/S3/WebDAV export
Screenshot filename template
Excluded apps
Privacy mode
```

## 6. Permissions

Bag End will require macOS permissions.

Required:

```text
Screen Recording permission
```

Potentially required depending on implementation:

```text
Accessibility permission
Input Monitoring permission
Files and Folders permission
```

Permission flow:

```text
First launch
    ↓
Onboarding explains why Screen Recording is needed
    ↓
User opens System Settings
    ↓
User grants permission
    ↓
User restarts Bag End if required
```

During development, screen capture permissions can reset or behave inconsistently if code signing identity changes. Use a stable Apple Development signing identity for debug builds when possible.

## 7. Data flow

### 7.1 Capture to shelf

```text
Hotkey event
    ↓
ShortcutManager
    ↓
CaptureCoordinator
    ↓
RegionSelectionOverlay
    ↓
ScreenCaptureService
    ↓
ScreenshotPostProcessor
    ↓
FileStorageService
    ↓
MetadataStore
    ↓
ScreenshotRepository publishes update
    ↓
ShelfWindowController opens shelf
```

### 7.2 Drag screenshot out

```text
User starts drag on ScreenshotCardView
    ↓
DragItemProvider prepares item
    ↓
Pasteboard receives file URL + PNG representation
    ↓
Target app accepts image/file
    ↓
ScreenshotRepository updates last_dragged_at
```

### 7.3 Cleanup

```text
CleanupScheduler runs periodically
    ↓
Fetch expired unpinned screenshots
    ↓
Delete files and thumbnails
    ↓
Mark metadata as deleted or remove rows
    ↓
Refresh shelf
```

## 8. MVP scope

MVP must include:

```text
Menu bar app
Configurable hotkey
Area screenshot capture
Screenshot saved into app storage
Floating shelf from top center/notch area
Recent screenshot cards
Drag screenshot into other apps
Delete one screenshot
Clear all unpinned screenshots
Basic settings
Auto-cleanup
```

MVP must not include:

```text
OCR
Cloud sync
Complex annotation editor
Scrolling capture
Video recording
Team sharing
Full screenshot history search
```

## 9. Later architecture extensions

### 9.1 OCR

Add a local OCR pipeline using Apple Vision.

```text
Screenshot saved
    ↓
OCR service extracts text
    ↓
Text stored in SQLite
    ↓
Search UI becomes available
```

### 9.2 Annotation editor

Add a lightweight annotation editor:

```text
Crop
Arrow
Rectangle
Blur
Text
Highlight
```

This should be a separate module, not part of core capture.

### 9.3 S3-compatible archive

Optional Pro feature:

```text
Pinned screenshots → upload to S3/MinIO/WebDAV
Metadata → local SQLite + remote manifest
```

This feature fits well with a future data/knowledge workflow.

## 10. Testing strategy

Manual test matrix:

```text
MacBook built-in display with notch
External monitor without notch
Multiple displays
Light mode
Dark mode
Auto-hidden menu bar
Different display scaling modes
Finder drag
Telegram drag
Discord drag
Slack drag
Notion drag
Browser file input drag
Preview drag
Copy/paste into image editor
```

Automated tests:

```text
SettingsStore tests
MetadataStore tests
FileStorageService tests
CleanupScheduler tests
ScreenshotRepository tests
Filename generation tests
```

UI tests can be added later but should not block MVP.

## 11. Non-goals

Bag End is not initially:

```text
A full screenshot editor
A cloud screenshot sharing platform
A video recording tool
A complete CleanShot X replacement
A system-wide clipboard manager
```

The initial product must stay narrow: capture, hold, drag, clean up.
