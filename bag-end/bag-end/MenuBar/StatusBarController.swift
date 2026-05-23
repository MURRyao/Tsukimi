import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: 34)
        super.init()
        configure()
    }

    private func configure() {
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.title = "BE"
            button.font = .systemFont(ofSize: 13, weight: .semibold)
            button.toolTip = "Bag End"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Shelf", action: #selector(showShelf), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Bag End", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func captureArea() {
        appState.captureArea()
    }

    @objc private func showShelf() {
        appState.showShelf()
    }

    @objc private func clearAll() {
        appState.clearUnpinnedScreenshots()
    }

    @objc private func showPreferences() {
        appState.showSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
