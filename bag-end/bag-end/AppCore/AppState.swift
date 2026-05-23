import AppKit
import Combine

final class AppState: ObservableObject {
    let settings: SettingsStore
    let repository: ScreenshotRepository

    @Published var lastErrorMessage: String?

    private let captureService: ScreenCaptureService
    private lazy var notchHostWindowController = NotchHostWindowController(appState: self)
    private var cancellables: Set<AnyCancellable> = []

    init(
        settings: SettingsStore = SettingsStore(),
        storage: FileStorageService = FileStorageService()
    ) {
        self.settings = settings
        self.repository = ScreenshotRepository(storage: storage, settings: settings)
        self.captureService = ScreencaptureScreenCaptureService(storage: storage)
    }

    func start() {
        do {
            try repository.load()
            try repository.cleanupExpired()
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
                let fileURL = try await captureService.captureArea()
                try repository.addCapturedScreenshot(at: fileURL)
                if settings.copyImageOnCapture {
                    DragItemProvider.copyImageToPasteboard(for: fileURL)
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

    func showNotchHandle() {
        notchHostWindowController.showHandle()
    }

    func hideShelf() {
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
        guard settings.autoHideShelf else { return }
        let delay = settings.autoHideDelay

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            await MainActor.run {
                self?.hideShelf()
            }
        }
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
            case .screenRecordingPermissionRequired:
                return "Bag End needs Screen Recording permission. Enable Bag End in System Settings > Privacy & Security > Screen & System Audio Recording, then fully quit and relaunch the app from Xcode so macOS reloads the permission."
            }
        }

        return error.localizedDescription
    }
}
