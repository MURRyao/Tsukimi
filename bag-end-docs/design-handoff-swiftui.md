# Bag End — SwiftUI Design Handoff

This document captures the current product mockup direction so it can be recreated in SwiftUI/AppKit without depending on Figma access.

## Design Direction

Bag End should feel like a small native macOS utility: quiet, translucent, fast, and local-first. The visual identity should use a restrained green palette to match the product name without turning the app into a decorative fantasy theme.

Core mood:

```text
Native macOS
Soft green material
Menu bar utility
Notch-aware floating shelf
Temporary screenshot rail
Drag-first screenshot cards
```

Avoid:

```text
Heavy editor UI
Bright SaaS green
Large marketing panels
Desktop file-manager styling
Cloud/account language in MVP
```

## Primary Screen

The primary preview is a macOS desktop scene with a translucent Bag End shelf dropping from the notch/top-center area.

Canvas reference:

```text
Desktop preview: 1512 x 982
Shelf frame: 940 x 246
Shelf position: top-center, y approximately 44
Shelf corner radius: 28
Shelf material: translucent green-tinted glass
```

SwiftUI/AppKit mapping:

```text
NSPanel or borderless NSWindow
Non-activating where practical
Transparent window background
SwiftUI content in NSHostingView
VisualEffect material behind shelf
Window positioned using active screen top-center
```

## Color Tokens

Use these tokens as the initial design constants.

```text
brandDeep:        #12351F
brandPrimary:     #2E7D32
brandAccent:      #43A047
brandSecondary:   #55735B
surfaceGreen:     #F4FFF5 at 78%
surfaceCard:      #F8FFF9 at 92%
trackGreen:       #D7EAD7
wallpaperA:        #EEF8EF
wallpaperB:        #D9ECD8
wallpaperWarm:     #F5F1E6
textPrimary:      #12351F
textSecondary:    #55735B
```

## Shelf Layout

The expanded shelf contains:

```text
Top row
- 34 x 34 app icon
- Title: "Bag End"
- Subtitle: "18 screenshots · temporary shelf · local only"
- Capture Area button
- Clear All button
- Pin Mode button

Middle rail
- Horizontal screenshot rail viewport
- 5-6 visible cards
- More cards clipped outside viewport
- Left/right fade hints

Bottom row
- Horizontal slide bar
- Filled range
- Draggable thumb
- Counter, e.g. "1-6 of 18"
```

Suggested shelf metrics:

```text
width: 940
height: 246
cornerRadius: 28
outerPadding: 24
topRowHeight: 54
railY: 78
railHeight: 118
slideBarY: 214
```

## Screenshot Card

Screenshot cards should behave like draggable file/image objects, not like static gallery thumbnails.

Card metrics:

```text
width: 136
height: 112
cornerRadius: 15
thumbnail: 120 x 72
thumbnailCornerRadius: 10
horizontalSpacing: 16
```

Card contents:

```text
Thumbnail preview
Pinned indicator dot
Delete button
Title
Metadata line: "PNG · local"
```

Interaction rules:

```text
Primary action: drag out
Secondary actions: delete, pin, copy, save as
Pinned state: green dot or pin symbol
Delete action: visible on hover or always visible in preview
```

Drag representations required later:

```text
file URL
PNG data
TIFF/NSImage
public.image
file promise if needed
```

## Slide Bar

The shelf needs a horizontal slide bar because the screenshot set can exceed the visible card rail.

Visual parts:

```text
Track: light green rounded capsule
Filled range: translucent brandPrimary
Thumb: white capsule with subtle green border
Grip: two small green horizontal lines
Counter: right-aligned current range
```

Behavior:

```text
Thumb position maps to scroll offset
Thumb width maps to visible range / total content width
Track click jumps toward position
Drag on thumb scrolls rail
Mouse wheel or trackpad horizontal scroll also scrolls rail
Counter updates as visible card range changes
```

Example:

```text
Total screenshots: 18
Visible cards: 6
Counter: 1-6 of 18
```

## Empty State

When no screenshots are available, keep the shelf compact and useful.

Content:

```text
Title: "No screenshots in Bag End"
Subtitle: "Press the capture hotkey. New screenshots stay off Desktop and appear here temporarily."
Primary action: "Capture Area"
```

Do not make the empty state feel like a marketing screen.

## Settings Preview

Settings should be a conventional macOS settings window, separate from the shelf.

Initial sections:

```text
General
Shortcuts
Shelf
Storage
Privacy
```

Initial controls:

```text
Show shelf after capture
Auto-clean unpinned screenshots
Copy image on capture
Capture Area Hotkey
```

Important copy:

```text
Screenshots are local by default.
No Desktop pollution.
No upload without explicit export/sync action.
No clipboard polling.
```

## SwiftUI Component Map

Suggested view structure:

```text
ShelfWindowController
└── BagEndShelfView
    ├── ShelfHeaderView
    ├── ScreenshotRailView
    │   └── ScreenshotCardView
    └── ScreenshotSlideBar

Settings
└── BagEndSettingsView
    ├── GeneralSettingsView
    ├── ShortcutSettingsView
    ├── ShelfSettingsView
    ├── StorageSettingsView
    └── PrivacySettingsView
```

## Implementation Notes

Use AppKit for the window and SwiftUI for shelf content.

```text
NSPanel / borderless NSWindow for floating shelf
NSVisualEffectView or SwiftUI material for translucent background
LazyHStack for screenshot cards
ScrollViewReader or custom scroll state for rail position
DragGesture for slide bar thumb
NSItemProvider / NSPasteboard for drag-out
```

For the first prototype, the slide bar can be visual-only if the card rail is implemented with native horizontal scrolling. Before MVP, connect the slide bar to the actual rail offset so it behaves like a real scrollbar.

