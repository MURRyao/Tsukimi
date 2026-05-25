import AppKit
import SwiftUI

final class ShelfWindowController {
    private let appState: AppState
    private var panel: NSPanel?
    private var handlePanel: NSPanel?

    init(appState: AppState) {
        self.appState = appState
    }

    func showHandle() {
        let handlePanel = handlePanel ?? makeHandlePanel()
        self.handlePanel = handlePanel
        positionHandle(handlePanel)
        handlePanel.orderFrontRegardless()
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        handlePanel?.orderOut(nil)
        position(panel)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
        showHandle()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: TsukimiDesign.Shelf.width,
                height: TsukimiDesign.Shelf.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false

        let view = TsukimiShelfView(
            appState: appState,
            repository: appState.repository,
            settings: appState.settings
        )
        let hostingView = NSHostingView(
            rootView: view.frame(
                width: TsukimiDesign.Shelf.width,
                height: TsukimiDesign.Shelf.height
            )
        )
        hostingView.frame = panel.contentRect(forFrameRect: panel.frame)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }

    private func makeHandlePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: TsukimiDesign.Shelf.handleWidth,
                height: TsukimiDesign.Shelf.handleHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true

        let view = NotchHandleView(revealAction: { [weak self] in
            self?.appState.showShelf()
        })
        let hostingView = NSHostingView(
            rootView: view.frame(
                width: TsukimiDesign.Shelf.handleWidth,
                height: TsukimiDesign.Shelf.handleHeight
            )
        )
        hostingView.frame = panel.contentRect(forFrameRect: panel.frame)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }

    private func position(_ panel: NSPanel) {
        let screen = activeScreen()
        let frame = screen.visibleFrame
        let width = min(TsukimiDesign.Shelf.width, frame.width - 32)
        let height = TsukimiDesign.Shelf.height
        let x = frame.midX - width / 2
        let y = frame.maxY - height - TsukimiDesign.Shelf.topOffset

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    private func positionHandle(_ panel: NSPanel) {
        let screen = activeScreen()
        let frame = screen.frame
        let width = TsukimiDesign.Shelf.handleWidth
        let height = TsukimiDesign.Shelf.handleHeight
        let x = frame.midX - width / 2
        let y = frame.maxY - height - 1

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    private func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
    }
}
