# codex.md — Bag End Development Instructions

## Project

Project name: **Bag End**

Bag End is a native macOS screenshot shelf. It captures screenshots with a flow similar to `Command + Shift + 4`, but instead of saving the screenshot to Desktop, it stores screenshots in a temporary shelf that drops down from the MacBook notch or from the top edge of the active display. The user can drag screenshots from the shelf into other apps.

## Main product goal

Implement this core workflow first:

```text
Press hotkey → select screen area → screenshot appears in shelf → drag screenshot into another app
```

Do not expand the scope until this workflow is stable.

## Technical stack

Use:

```text
Swift
SwiftUI
AppKit
ScreenCaptureKit where appropriate
FileManager
SQLite or lightweight manifest for metadata
NSPasteboard / NSItemProvider for drag-and-drop
Xcode project structure
```

Do not use:

```text
Electron
React Native
Flutter
Python GUI
Private macOS APIs
Cloud backend for MVP
```

## Product constraints

Bag End must be:

```text
Local-first
Fast
Native-feeling
Menu-bar-based
Notch-aware
Usable without cloud account
Safe with private screenshots
```

Bag End must not:

```text
Save screenshots to Desktop by default
Upload screenshots without explicit user action
Depend on private notch APIs
Become a full screenshot editor in MVP
Read clipboard constantly in the background
```

## Architecture boundaries

Respect these module boundaries:

```text
AppCore: app lifecycle, settings, permissions, shortcuts
Capture: region selection and screen capture
Shelf: floating shelf UI and shelf window behavior
Storage: file persistence, metadata, cleanup
DragDrop: pasteboard, file URL drag, image drag
MenuBar: status bar item and menu actions
Settings: user preferences UI
```

Do not put capture logic directly into SwiftUI views.  
Do not put storage logic directly into shelf cards.  
Do not let drag-and-drop code mutate storage except through repository methods.

## MVP scope

Implement only:

```text
Menu bar app
Configurable or hardcoded initial hotkey
Area screenshot capture
Local screenshot storage
Floating shelf
Screenshot thumbnails/cards
Drag screenshot out as file URL and image
Delete screenshot
Clear all unpinned screenshots
Basic settings
Auto-cleanup
```

Avoid for MVP:

```text
OCR
Cloud sync
Annotation editor
Scrolling capture
Video recording
Team sharing
AI image analysis
Complex search
```

## Coding style

Use:

```text
Clear names
Small types
Protocol-based services where useful
Dependency injection for testable services
MainActor for UI-facing state
async/await where appropriate
Result or throwing functions for fallible operations
```

Avoid:

```text
Massive view files
Global mutable state
Force unwraps
Silent catch blocks
Hardcoded absolute paths
Private APIs
Overengineering before MVP works
```

## Naming conventions

Use project/product name in user-facing text:

```text
Bag End
```

Use code-safe names:

```text
BagEndApp
BagEndSettings
BagEndShelf
ScreenshotRepository
CaptureCoordinator
ShelfWindowController
```

## File organization

Preferred structure:

```text
BagEnd/
├── App/
│   ├── BagEndApp.swift
│   └── AppDelegate.swift
├── AppCore/
├── Capture/
├── Shelf/
├── Storage/
├── DragDrop/
├── MenuBar/
├── Settings/
├── Shared/
└── Resources/
```

Tests:

```text
BagEndTests/
├── StorageTests/
├── SettingsTests/
├── CleanupTests/
└── FilenameTests/
```

Docs:

```text
docs/
├── architecture.md
├── roadmap.md
└── development-setup.md
```

## First implementation path

Follow this order:

1. Create a clean macOS SwiftUI app.
2. Add menu bar item.
3. Add a simple floating shelf window.
4. Add local screenshot storage folder.
5. Add temporary capture using `screencapture` command.
6. Show captured screenshots in shelf.
7. Implement drag-out using file URL.
8. Add delete and clear all.
9. Add basic hotkey.
10. Improve capture implementation.
11. Add native region selection overlay.
12. Add permission onboarding.

Do not skip directly to native capture if the basic user flow is not validated.

## Capture prototype rule

For the earliest prototype, it is acceptable to call the macOS `screencapture` command from Swift.

Example behavior:

```text
Run interactive region capture
Save image into Bag End app storage
Load image into shelf
```

This is a temporary implementation. It should be isolated behind `ScreenCaptureService` so that it can later be replaced.

## Drag-and-drop requirements

When dragging a screenshot card, provide as many compatible representations as practical:

```text
File URL
PNG data
TIFF/NSImage representation
public.image
```

The first required target is Finder.  
Then test Telegram, Discord, Slack, Notion, Obsidian, Preview, and browser file inputs.

## Storage rules

Store screenshots in:

```text
~/Library/Application Support/Bag End/screenshots/
```

Do not store in:

```text
Desktop
Downloads
Project directory
Temporary system folders without tracking
```

Each screenshot should have metadata:

```text
id
file path
thumbnail path
created date
width
height
file size
is pinned
expires at
last dragged at
```

## Privacy rules

Screenshots may contain sensitive data.

Therefore:

```text
No network upload by default
No analytics with screenshot contents
No OCR unless explicitly enabled later
No clipboard polling
Clear all must be obvious
Storage location must be documented
```

## UI rules

Shelf behavior:

```text
Appears after capture
Drops from notch/top-center
Shows newest screenshots first
Supports drag-out
Auto-hides if configured
Does not steal focus unless necessary
Works without notch
```

Visual style:

```text
Native macOS
Compact
Rounded
Subtle shadow
Dark/light mode support
Minimal animation
```

## Testing checklist

Before considering MVP complete, verify:

```text
Capture works on built-in display
Capture works on external monitor
Capture works in dark mode
Capture works in light mode
Drag to Finder works
Drag to Telegram or Discord works
Drag to browser upload field works
Delete works
Clear all works
Auto-cleanup works
App restart preserves pinned screenshots
Unpinned screenshots expire correctly
```

## Important warnings

Do not use private APIs to access or modify the notch.

Do not assume a global hotkey is always free. Add settings later so the user can change it.

Do not assume every app accepts the same drag representation. Implement multiple pasteboard representations.

Do not let permission errors fail silently. Show a clear onboarding or error state.

Do not make the first version too broad. The MVP is a shelf, not a screenshot suite.

## Current priority

Current priority:

```text
Build the smallest working Bag End prototype:
hotkey or menu action → area capture → shelf display → drag out
```
