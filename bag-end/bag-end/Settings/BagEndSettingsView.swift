import SwiftUI

struct BagEndSettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            ShelfSettingsView(settings: settings)
                .tabItem { Label("Shelf", systemImage: "rectangle.topthird.inset.filled") }

            StorageSettingsView(settings: settings)
                .tabItem { Label("Storage", systemImage: "externaldrive") }

            PrivacySettingsView()
                .tabItem { Label("Privacy", systemImage: "lock") }
        }
        .frame(width: 560, height: 360)
        .tint(BagEndDesign.ColorToken.brandPrimary)
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Toggle("Show shelf after capture", isOn: $settings.showShelfAfterCapture)
            Toggle("Copy image on capture", isOn: $settings.copyImageOnCapture)
            Text("Screenshots are local by default.")
                .foregroundStyle(BagEndDesign.ColorToken.textSecondary)
        }
        .formStyle(.grouped)
        .padding(24)
    }
}

private struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            ForEach(BagEndShortcut.allCases) { shortcut in
                LabeledContent(shortcut.title, value: shortcut.symbolicDisplayName)
            }

            Text("Global shortcuts are fixed for 0.2. Configurable hotkeys are planned for 0.5.")
                .foregroundStyle(BagEndDesign.ColorToken.textSecondary)
        }
        .formStyle(.grouped)
        .padding(24)
    }
}

private struct ShelfSettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Toggle("Auto-hide shelf", isOn: $settings.autoHideShelf)
            HStack {
                Text("Auto-hide delay")
                Slider(value: $settings.autoHideDelay, in: 3...20, step: 1)
                Text("\(Int(settings.autoHideDelay))s")
                    .monospacedDigit()
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .formStyle(.grouped)
        .padding(24)
    }
}

private struct StorageSettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Stepper("Max unpinned screenshots: \(settings.maxUnpinnedScreenshots)", value: $settings.maxUnpinnedScreenshots, in: 5...100)
            Stepper("Delete unpinned after: \(settings.deleteUnpinnedAfterHours)h", value: $settings.deleteUnpinnedAfterHours, in: 1...168)
            Text("~/Library/Application Support/Bag End/screenshots")
                .font(.caption)
                .foregroundStyle(BagEndDesign.ColorToken.textSecondary)
        }
        .formStyle(.grouped)
        .padding(24)
    }
}

private struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Text("No Desktop pollution.")
            Text("No upload without explicit export or sync action.")
            Text("No clipboard polling.")
        }
        .formStyle(.grouped)
        .padding(24)
    }
}
