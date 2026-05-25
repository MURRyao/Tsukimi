import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class NotchHostWindowController {
    private let appState: AppState
    private let presentationChanged: (Bool) -> Void
    private let model = NotchHostModel()
    private var panel: NSPanel?
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?

    init(appState: AppState, presentationChanged: @escaping (Bool) -> Void = { _ in }) {
        self.appState = appState
        self.presentationChanged = presentationChanged
    }

    func showHandle() {
        let panel = panel ?? makePanel()
        self.panel = panel
        model.presentation = .closed
        presentationChanged(false)
        applyFrame(expanded: false, animate: false)
        panel.orderFrontRegardless()
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.orderFrontRegardless()
        expand()
    }

    func hide() {
        collapse()
    }

    private func expand() {
        model.presentation = .expanded
        presentationChanged(true)
        applyFrame(expanded: true, animate: true)
        installOutsideClickMonitors()
    }

    private func collapse() {
        model.presentation = .closed
        presentationChanged(false)
        removeOutsideClickMonitors()
        applyFrame(expanded: false, animate: true)
        panel?.orderFrontRegardless()
    }

    private func makePanel() -> NSPanel {
        let geometry = NotchGeometryService.geometryForActiveScreen()
        let panel = NSPanel(
            contentRect: geometry.compactFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 4)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false

        let view = NotchHostView(
            appState: appState,
            repository: appState.repository,
            settings: appState.settings,
            model: model,
            openAction: { [weak self] in
                self?.expand()
            },
            closeAction: { [weak self] in
                self?.collapse()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = panel.contentRect(forFrameRect: panel.frame)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }

    private func applyFrame(expanded: Bool, animate: Bool) {
        guard let panel else { return }
        let geometry = NotchGeometryService.geometryForActiveScreen()
        let frame = expanded ? geometry.expandedFrame : geometry.compactFrame

        guard animate else {
            panel.setFrame(frame, display: true)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.28 : 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func installOutsideClickMonitors() {
        guard localMouseDownMonitor == nil, globalMouseDownMonitor == nil else { return }

        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            if self.shouldCollapse(for: event) {
                self.collapse()
            }
            return event
        }

        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            DispatchQueue.main.async {
                guard let self, self.shouldCollapse(for: event) else { return }
                self.collapse()
            }
        }
    }

    private func removeOutsideClickMonitors() {
        if let localMouseDownMonitor {
            NSEvent.removeMonitor(localMouseDownMonitor)
            self.localMouseDownMonitor = nil
        }

        if let globalMouseDownMonitor {
            NSEvent.removeMonitor(globalMouseDownMonitor)
            self.globalMouseDownMonitor = nil
        }
    }

    private func shouldCollapse(for event: NSEvent) -> Bool {
        guard model.presentation == .expanded, let panel else { return false }
        if event.window === panel {
            return false
        }

        return !panel.frame.contains(NSEvent.mouseLocation)
    }
}

private final class NotchHostModel: ObservableObject {
    enum Presentation {
        case closed
        case peeking
        case dragTarget
        case expanded
    }

    @Published var presentation: Presentation = .closed
}

private struct NotchHostView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var repository: ScreenshotRepository
    @ObservedObject var settings: SettingsStore
    @ObservedObject var model: NotchHostModel

    let openAction: () -> Void
    let closeAction: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            if model.presentation == .expanded {
                TsukimiShelfView(
                    appState: appState,
                    repository: repository,
                    settings: settings,
                    closeAction: closeAction
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.92, anchor: .top).combined(with: .opacity)
                ))
            } else {
                compactIsland
                    .padding(.top, 0)
                    .transition(.scale(scale: 0.88, anchor: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.32, dampingFraction: 0.84), value: model.presentation)
    }

    private var compactIsland: some View {
        VStack(spacing: 4) {
            HStack(spacing: 9) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: statusColor.opacity(0.5), radius: 7)

                if model.presentation != .closed {
                    Text(compactTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Image(systemName: model.presentation == .dragTarget ? "tray.and.arrow.down.fill" : "chevron.down")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(width: compactWidth, height: TsukimiDesign.Shelf.notchHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(.black.opacity(0.97))
                    .shadow(color: .black.opacity(0.24), radius: 14, y: 6)
            )

            Capsule(style: .continuous)
                .fill(statusColor.opacity(model.presentation == .closed ? 0.68 : 0.95))
                .frame(width: model.presentation == .closed ? 48 : 72, height: 5)
        }
        .offset(y: dragOffset)
        .contentShape(Rectangle())
        .onHover { isHovering in
            guard model.presentation != .expanded, model.presentation != .dragTarget else { return }
            model.presentation = isHovering ? .peeking : .closed
        }
        .onDrop(of: [.fileURL, .image], isTargeted: Binding(
            get: { model.presentation == .dragTarget },
            set: { isTargeted in
                guard model.presentation != .expanded else { return }
                model.presentation = isTargeted ? .dragTarget : .closed
            }
        )) { _ in
            openAction()
            return false
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = min(max(value.translation.height, 0), 36)
                    if model.presentation == .closed {
                        model.presentation = .peeking
                    }
                }
                .onEnded { value in
                    let isTap = abs(value.translation.width) < 4 && abs(value.translation.height) < 4
                    let isPullDown = value.translation.height > 14
                    dragOffset = 0

                    if isTap || isPullDown {
                        openAction()
                    } else {
                        model.presentation = .closed
                    }
                }
        )
    }

    private var compactTitle: String {
        if repository.items.isEmpty {
            return AppBrand.displayName
        }

        return "\(repository.items.count) screenshot\(repository.items.count == 1 ? "" : "s")"
    }

    private var compactWidth: CGFloat {
        switch model.presentation {
        case .closed:
            return TsukimiDesign.Shelf.notchWidth
        case .peeking:
            return TsukimiDesign.Shelf.handleWidth
        case .dragTarget:
            return TsukimiDesign.Shelf.handleWidth + 34
        case .expanded:
            return TsukimiDesign.Shelf.handleWidth
        }
    }

    private var statusColor: Color {
        model.presentation == .dragTarget ? .white : TsukimiDesign.ColorToken.brandAccent
    }
}
