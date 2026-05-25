import AppKit
import Combine

final class AppState: ObservableObject {
    let settings: SettingsStore
    let repository: ScreenshotRepository

    @Published var lastErrorMessage: String?

    private let captureService: ScreenCaptureService
    private let hotKeyService = GlobalHotKeyService()
    private lazy var notchHostWindowController = NotchHostWindowController(
        appState: self,
        presentationChanged: { [weak self] isExpanded in
            self?.isShelfExpanded = isExpanded
        }
    )
    private var isShelfExpanded = false
    private var autoHideTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(
        settings: SettingsStore = SettingsStore(),
        storage: FileStorageService = FileStorageService()
    ) {
        self.settings = settings
        self.repository = ScreenshotRepository(storage: storage, settings: settings)
        self.captureService = NativeScreenCaptureService(
            storage: storage,
            fallback: ScreencaptureScreenCaptureService(storage: storage)
        )
    }

    func start() {
        do {
            try repository.load()
            try repository.cleanupExpired()
            try registerHotKeys()
            showNotchHandle()
        } catch {
            presentError(error)
        }
    }

    func captureArea() {
        Task { @MainActor in
            do {
                hideShelf()
                try? await Task.sleep(for: .milliseconds(180))
                let captureResult = try await captureService.captureArea()
                try repository.addCapturedScreenshot(captureResult)
                if settings.copyImageOnCapture {
                    DragItemProvider.copyImageToPasteboard(for: captureResult.fileURL)
                }
                if settings.showShelfAfterCapture {
                    showShelf()
                }
            } catch ScreenCaptureError.cancelled {
                return
            } catch {
                presentError(error)
            }
        }
    }

    func showShelf() {
        notchHostWindowController.show()
        scheduleAutoHideIfNeeded()
    }

    func toggleShelf() {
        if isShelfExpanded {
            hideShelf()
        } else {
            showShelf()
        }
    }

    func showNotchHandle() {
        notchHostWindowController.showHandle()
    }

    func hideShelf() {
        autoHideTask?.cancel()
        autoHideTask = nil
        notchHostWindowController.hide()
    }

    func clearUnpinnedScreenshots() {
        do {
            try repository.clearUnpinned()
        } catch {
            presentError(error)
        }
    }

    func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func presentError(_ error: Error) {
        let message = BagEndErrorMessage.describe(error)
        lastErrorMessage = message

        let alert = NSAlert()
        alert.messageText = "Bag End"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.icon = NSApp.applicationIconImage

        if case ScreenCaptureError.screenRecordingPermissionRequired = error {
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Quit Bag End")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn,
               let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            } else if response == .alertSecondButtonReturn {
                NSApp.terminate(nil)
            }
            return
        }

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func scheduleAutoHideIfNeeded() {
        autoHideTask?.cancel()
        autoHideTask = nil

        guard settings.autoHideShelf else { return }
        let delay = settings.autoHideDelay

        autoHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.hideShelf()
            }
        }
    }

    private func registerHotKeys() throws {
        try hotKeyService.start(registrations: [
            GlobalHotKeyRegistration(shortcut: .captureArea) { [weak self] in
                self?.captureArea()
            },
            GlobalHotKeyRegistration(shortcut: .toggleShelf) { [weak self] in
                self?.toggleShelf()
            }
        ])
    }
}

enum BagEndErrorMessage {
    static func describe(_ error: Error) -> String {
        if let captureError = error as? ScreenCaptureError {
            switch captureError {
            case .cancelled:
                return "Capture was cancelled."
            case .failed(let status):
                return "Screen capture failed with exit code \(status). Check Screen Recording permission in System Settings."
            case .missingOutput:
                return "Screen capture did not create an image. Try again or check Screen Recording permission."
            case .couldNotLaunch:
                return "Bag End could not start macOS screencapture."
            case .nativeCaptureFailed:
                return "Bag End could not capture the selected region. Try again, or check Screen Recording permission in System Settings."
            case .screenRecordingPermissionRequired:
                return "Bag End needs Screen Recording permission. Enable Bag End in System Settings > Privacy & Security > Screen & System Audio Recording, then fully quit and relaunch the app from Xcode so macOS reloads the permission."
            }
        }

        if let hotKeyError = error as? GlobalHotKeyError {
            switch hotKeyError {
            case .handlerInstallFailed(let status):
                return "Bag End could not install the global hotkey handler. macOS returned status \(status)."
            case .registrationFailed(let shortcut, let status):
                return "Bag End could not register \(shortcut.symbolicDisplayName) for \(shortcut.title). Another app may already use it. macOS returned status \(status)."
            }
        }

        return error.localizedDescription
    }
}
