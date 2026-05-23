# Bag End — Roadmap

## Product vision

Bag End is a native macOS screenshot shelf that captures screenshots and temporarily stores them in a notch/top-edge shelf for quick drag-and-drop into other apps.

The first goal is not to replace CleanShot X, Shottr, or Snagit. The first goal is to make one narrow workflow excellent:

```text
Make screenshot → keep it temporarily → drag it where needed → do not pollute Desktop
```

## Version 0.1 — Technical prototype

Goal: prove that screenshots can be captured, stored, shown, and dragged out.

Scope:

```text
Create macOS app project
Run as menu bar app
Implement basic hotkey
Use screencapture CLI fallback for area capture
Save PNG into Application Support folder
Show simple floating window with screenshot thumbnails
Drag screenshot file into Finder and other apps
Clear screenshots manually
```

Acceptance criteria:

```text
User presses hotkey
User selects area
Screenshot appears in Bag End shelf
User drags it into Finder
No screenshot is created on Desktop
```

Notes:

- UI quality is not important yet.
- Capture implementation may be temporary.
- The goal is to validate the workflow.

## Version 0.2 — MVP shelf

Goal: make the app usable daily for a small group of testers.

Scope:

```text
Replace rough floating window with polished shelf
Add notch/top-center positioning
Add screenshot cards
Add delete button per screenshot
Add clear all button
Add shelf show/hide hotkey
Add auto-hide behavior
Add max item count
Add basic settings screen
```

Acceptance criteria:

```text
Shelf opens quickly
Shelf does not steal focus unnecessarily
Screenshots are draggable
Shelf works on MacBook display and external monitor
Settings persist after restart
```

## Version 0.3 — Native capture pipeline

Goal: reduce dependence on temporary CLI capture and move toward native macOS behavior.

Scope:

```text
Implement custom region selection overlay
Add native capture backend
Normalize Retina scaling
Support multi-display capture
Improve capture result metadata
Improve permission onboarding
```

Acceptance criteria:

```text
Area selection feels close to Command + Shift + 4
Captured image dimensions are correct on Retina displays
Capture works on external monitors
Permission failure gives clear instructions
```

## Version 0.4 — Drag-and-drop reliability

Goal: make drag-out work across real user apps.

Scope:

```text
Improve NSPasteboard representations
Support file URL drag
Support PNG data drag
Support TIFF/NSImage representation
Add copy image action
Add save as action
Add file promise support if needed
Test major target apps
```

Test targets:

```text
Finder
Preview
Telegram
Discord
Slack
Notion
Obsidian
VS Code
Figma
Browser file input
Mail
```

Acceptance criteria:

```text
Dragging a screenshot works in most common apps
Copy image works in image-aware apps
Save as works reliably
```

## Version 0.5 — First private beta

Goal: use the app as a real daily tool.

Scope:

```text
Onboarding screen
Permission checklist
Configurable hotkeys
Launch at login
Crash-safe storage
Auto-cleanup for unpinned screenshots
Pin screenshot
Basic diagnostics logs
```

Acceptance criteria:

```text
New user can install, grant permissions, set hotkey, and capture screenshot without reading documentation
Pinned screenshots are not deleted
Unpinned screenshots are cleaned automatically
```

## Version 0.6 — Polish and distribution

Goal: prepare for public release outside the App Store.

Scope:

```text
App icon
DMG packaging
Developer ID signing
Notarization
Update mechanism investigation
Website/README
Privacy policy
Issue templates
```

Acceptance criteria:

```text
App can be installed from DMG
macOS Gatekeeper accepts the app
No scary unsigned app warning
User can quit, update, and uninstall cleanly
```

## Version 0.7 — Lightweight annotation

Goal: add common screenshot edits without becoming a full editor.

Scope:

```text
Quick crop
Arrow
Rectangle
Text
Blur
Highlight
Duplicate edited copy
```

Acceptance criteria:

```text
User can annotate a screenshot quickly
Original screenshot remains recoverable or duplicated
Editor does not slow down basic capture flow
```

## Version 0.8 — Search and OCR

Goal: make pinned screenshots more useful.

Scope:

```text
Use Apple Vision for OCR
Store recognized text in SQLite
Search pinned screenshots
Filter by date
Filter by source display or app if available
```

Acceptance criteria:

```text
Text from screenshots can be searched locally
OCR can be disabled
No network access is required
```

## Version 0.9 — Archive integrations

Goal: provide controlled long-term storage.

Potential integrations:

```text
Local archive folder
iCloud Drive folder
S3-compatible storage
MinIO
WebDAV
Obsidian export
Markdown export
```

Acceptance criteria:

```text
Pinned screenshots can be exported to configured archive
Upload/export is explicit
Local-only mode remains the default
```

## Version 1.0 — Stable release

Goal: stable, focused macOS utility.

Required features:

```text
Reliable area capture
Reliable shelf
Reliable drag-and-drop
Configurable hotkeys
Permission onboarding
Local storage
Auto-cleanup
Pinning
Basic settings
Signed and notarized build
```

Explicitly deferred after 1.0:

```text
Video recording
Scrolling capture
Team accounts
Cloud collaboration
Full screenshot editor
AI features
```

## Future ideas

Possible post-1.0 features:

```text
Raycast extension
Alfred workflow
Quick Look plugin
Obsidian plugin
Figma plugin
S3/MinIO screenshot archive
Local LLM description of screenshots
Automatic sensitive-content warning
Project-based shelves
Temporary share links
```

## Development order

Recommended implementation order:

```text
1. Create project skeleton
2. Menu bar app
3. Storage service
4. Temporary capture using screencapture
5. Shelf window
6. Drag-out support
7. Settings and hotkeys
8. Cleanup scheduler
9. Native capture overlay
10. Polish and signing
```

Do not start with OCR, cloud sync, or annotation. Those features are attractive but not essential for validating the core product.
