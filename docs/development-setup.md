# Tsukimi — Development Setup

## 1. Can this be developed in Visual Studio Code?

Yes, but with an important limitation.

You can use **Visual Studio Code** as the main code editor for Swift files, Markdown documentation, Git operations, and AI-assisted coding. However, you should still install and use **Xcode** because macOS app development depends on Apple's build system, SDKs, signing tools, entitlements, asset catalogs, debugging tools, and app packaging.

Recommended workflow:

```text
VS Code: everyday editing, Markdown, Git, Codex work
Xcode: project creation, build settings, signing, entitlements, debugging, archive/notarization
Terminal: git, swift build where applicable, xcodebuild, scripts
```

For a native macOS app like Tsukimi, do not try to avoid Xcode completely.

## 2. Required software

Install:

```text
Xcode
Xcode Command Line Tools
Visual Studio Code
Swift extension for VS Code
Git
Homebrew
```

Optional but useful:

```text
SwiftFormat
SwiftLint
xcbeautify
create-dmg
The Unarchiver or Keka for packaging tests
Raycast or Alfred for productivity
```

## 3. Xcode

Install Xcode from the Mac App Store or Apple Developer website.

After installation, run:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
swift --version
```

Accept the license if needed:

```bash
sudo xcodebuild -license accept
```

Xcode is required for:

```text
macOS SDK
Swift compiler integration
AppKit and SwiftUI development
Entitlements
Code signing
Screen Recording permission behavior
App archive
Developer ID signing
Notarization
```

## 4. Xcode Command Line Tools

Install:

```bash
xcode-select --install
```

Check:

```bash
xcode-select -p
```

Expected path when full Xcode is selected:

```text
/Applications/Xcode.app/Contents/Developer
```

## 5. Visual Studio Code setup

Install VS Code.

Then install the Swift extension recommended by the Swift project.

Useful VS Code extensions:

```text
Swift
GitLens
Error Lens
Markdown All in One
Even Better TOML
YAML
Code Spell Checker
```

Optional AI tools:

```text
OpenAI Codex CLI / Codex integration
Claude Code
Continue
GitHub Copilot
```

VS Code is suitable for:

```text
Editing Swift files
Editing Markdown docs
Writing tests
Working with agents
Reviewing diffs
Managing Git branches
```

VS Code is weaker for:

```text
SwiftUI previews
Entitlements
Signing
Asset catalogs
Complex Xcode project settings
Native app debugging
Archive/export/notarization
```

## 6. Homebrew

Install Homebrew if it is not installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Useful packages:

```bash
brew install git swiftformat swiftlint xcbeautify create-dmg
```

Optional:

```bash
brew install sqlite
```

## 7. Git setup

Check identity:

```bash
git config --global user.name
git config --global user.email
```

Set identity if needed:

```bash
git config --global user.name "Dmitry"
git config --global user.email "your-email@example.com"
```

Recommended repository structure:

```text
Tsukimi/
├── Tsukimi/
│   ├── Tsukimi.xcodeproj
│   ├── Tsukimi/
│   ├── TsukimiTests/
│   └── TsukimiUITests/
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   └── development-setup.md
├── codex.md
├── README.md
└── .gitignore
```

## 8. Create the Xcode project

In Xcode:

```text
File → New → Project
macOS → App
Product Name: Tsukimi
Interface: SwiftUI
Language: Swift
Use Core Data: No
Include Tests: Yes
```

Recommended bundle identifier:

```text
com.dbi14759.tsukimi
```

Recommended minimum macOS target:

```text
macOS 14 or later for development simplicity
```

You may later lower or raise the target depending on ScreenCaptureKit and UI needs.

## 9. Initial app type

Tsukimi should be a menu bar utility.

Early implementation may still show a normal app window for debugging. Later, switch to:

```text
Menu bar item
Optional hidden Dock icon
Settings window
Floating shelf window
```

Expected app components:

```text
TsukimiApp.swift
AppDelegate.swift
StatusBarController.swift
ShelfWindowController.swift
SettingsView.swift
```

## 10. Permissions to expect

Tsukimi will need Screen Recording permission for screen capture.

Depending on implementation, it may also need:

```text
Accessibility
Input Monitoring
Files and Folders
```

During development, if screen capture stops working:

```text
System Settings → Privacy & Security → Screen Recording
Remove old Tsukimi entries
Add or re-enable the current build
Restart Tsukimi
```

If permissions reset on every rebuild or relaunch, macOS is probably seeing each build as a different app identity. Screen Recording permission is stored by TCC against the bundle identifier plus the app's code-signing designated requirement. An ad-hoc or "Sign to Run Locally" debug build can change that identity often enough that the old permission no longer matches.

Recommended fix:

```text
Xcode → Tsukimi target → Signing & Capabilities
Team: select a real Apple Development team
Signing Certificate: Apple Development
Bundle Identifier: keep stable, currently com.dbi14759.tsukimi
```

Then clean the stale TCC entry once:

```bash
tccutil reset ScreenCapture com.dbi14759.tsukimi
```

Launch the same signed app again, grant Screen Recording permission, fully quit Tsukimi, and relaunch it. After that, do not switch between differently signed copies of `Tsukimi.app` while testing the permission path.

Useful checks:

```bash
codesign -dv --verbose=4 /path/to/Tsukimi.app
codesign -d -r- /path/to/Tsukimi.app
```

The TeamIdentifier and designated requirement should stay stable between development builds.

## 11. Suggested development commands

Open project from terminal:

```bash
open Tsukimi/Tsukimi.xcodeproj
```

Build from terminal:

```bash
xcodebuild -project Tsukimi/Tsukimi.xcodeproj -scheme Tsukimi -configuration Debug build | xcbeautify
```

Run tests:

```bash
xcodebuild test -project Tsukimi/Tsukimi.xcodeproj -scheme Tsukimi -destination 'platform=macOS' | xcbeautify
```

Format Swift:

```bash
swiftformat Tsukimi/Tsukimi Tsukimi/TsukimiTests
```

Lint Swift:

```bash
swiftlint
```

## 12. Recommended .gitignore

```gitignore
.DS_Store
*.xcuserstate
xcuserdata/
DerivedData/
.build/
.swiftpm/
.env
.env.local
*.log
*.dSYM.zip
*.dSYM
Tsukimi.app
*.dmg
```

## 13. Recommended first implementation steps

Step 1:

```text
Create macOS SwiftUI app in Xcode.
Commit clean project.
```

Step 2:

```text
Add menu bar item.
Add placeholder settings window.
Add placeholder shelf window.
```

Step 3:

```text
Add temporary screenshot capture using the macOS screencapture command.
Save result into Application Support/Tsukimi/screenshots.
```

Step 4:

```text
Display screenshots in shelf.
```

Step 5:

```text
Implement drag-out as file URL.
```

Step 6:

```text
Add hotkey.
```

Step 7:

```text
Replace temporary capture path with native capture/selection implementation.
```

## 14. Development caution

Do not begin with cloud sync, OCR, or annotation. First prove:

```text
capture → shelf → drag out
```

Everything else is secondary.
