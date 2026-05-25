# Tsukimi

Native macOS screenshot shelf for keeping quick screenshots off the Desktop.

Tsukimi is a small menu bar utility for capturing screen regions into a temporary local shelf. It follows the familiar `Command + Shift + 4` style of interaction, but saves captures into a notch-aware shelf instead of cluttering the Desktop. Screenshots can be dragged directly from Tsukimi into other apps as files or images.

## Status

Tsukimi is an early native macOS prototype. The core workflow is implemented first:

```text
Press hotkey -> select screen area -> screenshot appears in shelf -> drag it into another app
```

The repository, Xcode project, targets, module, bundle identifiers, and user-facing names now use the Tsukimi name.

## Features

- Menu bar macOS app with a compact status item.
- Global hotkeys for area capture and shelf visibility.
- Native region selection overlay.
- ScreenCaptureKit-based capture with a `screencapture` fallback path.
- Floating translucent screenshot shelf positioned near the notch or top edge.
- Local screenshot storage in Application Support.
- Drag screenshots into other apps via file URL and image pasteboard data.
- Pin, delete, and clear unpinned screenshots.
- Optional copy-to-clipboard on capture.
- Auto-hide shelf behavior.
- Automatic cleanup for temporary unpinned screenshots.
- Local-first privacy model: screenshots are not uploaded.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Control + Option + S` | Capture area |
| `Control + Option + B` | Show or hide shelf |

## Requirements

- macOS with Screen Recording permission available.
- Xcode with the macOS SDK.
- Xcode Command Line Tools.
- Git.

Optional development tools:

- SwiftFormat
- SwiftLint
- xcbeautify

## Build

Open the Xcode project:

```bash
open Tsukimi/Tsukimi.xcodeproj
```

Build from the command line:

```bash
xcodebuild -project Tsukimi/Tsukimi.xcodeproj -scheme Tsukimi -configuration Debug build
```

Run tests:

```bash
xcodebuild test -project Tsukimi/Tsukimi.xcodeproj -scheme Tsukimi -destination 'platform=macOS'
```

If `xcbeautify` is installed:

```bash
xcodebuild test -project Tsukimi/Tsukimi.xcodeproj -scheme Tsukimi -destination 'platform=macOS' | xcbeautify
```

## Permissions

Tsukimi needs Screen Recording permission to capture selected regions.

If capture fails, enable the app in:

```text
System Settings -> Privacy & Security -> Screen & System Audio Recording
```

After changing permission, fully quit and relaunch Tsukimi so macOS reloads the permission state.

For development permission resets:

```bash
tccutil reset ScreenCapture com.dbi14759.tsukimi
```

## Storage

Screenshots are stored locally:

```text
~/Library/Application Support/Tsukimi/screenshots/
```

Metadata is tracked in:

```text
~/Library/Application Support/Tsukimi/manifest.json
```

Unpinned screenshots are temporary by default. Pinned screenshots are kept until the user deletes them.

## Project Structure

```text
Tsukimi/
├── Tsukimi/
│   ├── App/
│   ├── AppCore/
│   ├── Capture/
│   ├── DragDrop/
│   ├── Hotkeys/
│   ├── MenuBar/
│   ├── Settings/
│   ├── Shelf/
│   ├── Shared/
│   └── Storage/
├── Tsukimi.xcodeproj/
├── TsukimiTests/
└── TsukimiUITests/
```

Additional documentation lives in `docs/`:

- `architecture.md`
- `development-setup.md`
- `design-handoff-swiftui.md`
- `roadmap.md`

## Design Principles

- Fast capture without file naming or export dialogs.
- Temporary by default.
- Drag-first workflow.
- Native macOS behavior.
- Desktop stays clean.
- Local-first privacy.
- Notch-aware, but not dependent on private macOS APIs.

## Roadmap

- Improve capture permission onboarding.
- Add configurable shortcuts.
- Polish shelf interactions and empty states.
- Add packaging and notarization workflow.
- Expand focused test coverage for capture, storage, cleanup, and settings.

## GitHub Description

Native macOS screenshot shelf that captures selected regions into a local notch-aware tray for quick drag-and-drop, without cluttering the Desktop.
