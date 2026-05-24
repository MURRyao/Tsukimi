import AppKit
import CoreGraphics
import ScreenCaptureKit

protocol RegionSelectionService {
    func selectRegion() async throws -> CGRect
}

final class NativeScreenCaptureService: ScreenCaptureService {
    private let storage: FileStorageService
    private let regionSelectionService: RegionSelectionService
    private let fallback: ScreenCaptureService?

    init(
        storage: FileStorageService,
        regionSelectionService: RegionSelectionService = OverlayRegionSelectionService(),
        fallback: ScreenCaptureService? = nil
    ) {
        self.storage = storage
        self.regionSelectionService = regionSelectionService
        self.fallback = fallback
    }

    func captureArea() async throws -> ScreenCaptureResult {
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenCaptureError.screenRecordingPermissionRequired
        }

        let selectedRect = try await regionSelectionService.selectRegion()
        try? await Task.sleep(for: .milliseconds(90))

        do {
            return try await capture(selectedRect: selectedRect)
        } catch {
            if let fallback {
                return try await fallback.captureArea()
            }

            throw error
        }
    }

    private func capture(selectedRect: CGRect) async throws -> ScreenCaptureResult {
        let rect = selectedRect.standardized
        guard rect.width >= 1, rect.height >= 1 else {
            throw ScreenCaptureError.cancelled
        }

        let displayIDs = NSScreen.screens.compactMap { screen -> CGDirectDisplayID? in
            guard let displayID = screen.displayID else { return nil }
            let intersection = screen.frame.intersection(rect)
            guard intersection.width > 0, intersection.height > 0 else { return nil }
            return displayID
        }

        guard !displayIDs.isEmpty else {
            throw ScreenCaptureError.nativeCaptureFailed
        }

        let outputImage = try await SCScreenshotManager.captureImage(in: rect)
        guard let pngData = NSBitmapImageRep(cgImage: outputImage).representation(using: .png, properties: [:]) else {
            throw ScreenCaptureError.nativeCaptureFailed
        }

        let outputURL = try storage.makeScreenshotFileURL()
        try pngData.write(to: outputURL, options: .atomic)
        let scale = rect.width > 0 ? CGFloat(outputImage.width) / rect.width : 1

        return ScreenCaptureResult(
            fileURL: outputURL,
            backend: .native,
            pixelSize: CGSize(width: outputImage.width, height: outputImage.height),
            scale: scale,
            displayIDs: displayIDs,
            selectedRect: rect
        )
    }
}

final class OverlayRegionSelectionService: RegionSelectionService {
    private var activeController: CaptureSelectionOverlayController?

    func selectRegion() async throws -> CGRect {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let controller = CaptureSelectionOverlayController { [weak self] result in
                    self?.activeController = nil
                    continuation.resume(with: result)
                }
                activeController = controller
                controller.show()
            }
        } onCancel: {
            Task { @MainActor in
                activeController?.cancel()
                activeController = nil
            }
        }
    }
}

private final class CaptureSelectionOverlayController {
    private let completion: (Result<CGRect, Error>) -> Void
    private var window: CaptureSelectionWindow?
    private var isFinished = false

    init(completion: @escaping (Result<CGRect, Error>) -> Void) {
        self.completion = completion
    }

    func show() {
        guard let frame = NSScreen.screens.map(\.frame).reduce(nil, { partial, frame in
            partial?.union(frame) ?? frame
        }) else {
            finish(.failure(ScreenCaptureError.nativeCaptureFailed))
            return
        }

        let selectionView = CaptureSelectionView(frame: CGRect(origin: .zero, size: frame.size))
        selectionView.onComplete = { [weak self] rect in
            guard rect.width >= 4, rect.height >= 4 else {
                self?.finish(.failure(ScreenCaptureError.cancelled))
                return
            }

            self?.finish(.success(rect.offsetBy(dx: frame.minX, dy: frame.minY)))
        }
        selectionView.onCancel = { [weak self] in
            self?.finish(.failure(ScreenCaptureError.cancelled))
        }

        let window = CaptureSelectionWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.contentView = selectionView
        window.hasShadow = false
        window.isOpaque = false
        window.level = .screenSaver
        window.titleVisibility = .hidden
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(selectionView)
    }

    func cancel() {
        finish(.failure(ScreenCaptureError.cancelled))
    }

    private func finish(_ result: Result<CGRect, Error>) {
        guard !isFinished else { return }
        isFinished = true
        window?.orderOut(nil)
        window = nil
        completion(result)
    }
}

private final class CaptureSelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class CaptureSelectionView: NSView {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        bounds.fill()

        guard let selectionRect else { return }

        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.setBlendMode(.clear)
            context.fill(selectionRect)
            context.restoreGState()
        }

        NSColor.white.withAlphaComponent(0.92).setStroke()
        let border = NSBezierPath(roundedRect: selectionRect, xRadius: 3, yRadius: 3)
        border.lineWidth = 1.5
        border.stroke()

        NSColor.systemGreen.withAlphaComponent(0.95).setStroke()
        let accent = NSBezierPath(roundedRect: selectionRect.insetBy(dx: -1, dy: -1), xRadius: 4, yRadius: 4)
        accent.lineWidth = 1
        accent.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        guard let selectionRect else {
            onCancel?()
            return
        }

        onComplete?(selectionRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    private var selectionRect: CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
