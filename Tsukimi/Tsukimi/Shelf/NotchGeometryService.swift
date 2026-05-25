import AppKit

struct NotchGeometry {
    let screen: NSScreen
    let compactFrame: NSRect
    let expandedFrame: NSRect
    let hasHardwareNotch: Bool
    let notchWidth: CGFloat
}

enum NotchGeometryService {
    static func geometryForActiveScreen() -> NotchGeometry {
        geometry(for: activeScreen())
    }

    static func geometry(for screen: NSScreen) -> NotchGeometry {
        let screenFrame = screen.frame
        let hardwareNotchWidth = detectedNotchWidth(on: screen)
        let hasHardwareNotch = hardwareNotchWidth > 0
        let visualNotchWidth = hasHardwareNotch ? hardwareNotchWidth : TsukimiDesign.Shelf.notchWidth

        let compactWidth = max(TsukimiDesign.Shelf.handleWidth + 44, visualNotchWidth + 44)
        let compactHeight = TsukimiDesign.Shelf.handleHeight
        let compactFrame = NSRect(
            x: screenFrame.midX - compactWidth / 2,
            y: screenFrame.maxY - compactHeight - 1,
            width: compactWidth,
            height: compactHeight
        )

        let expandedWidth = min(TsukimiDesign.Shelf.width, screenFrame.width - 32)
        let expandedHeight = TsukimiDesign.Shelf.height
        let expandedFrame = NSRect(
            x: screenFrame.midX - expandedWidth / 2,
            y: screenFrame.maxY - expandedHeight - TsukimiDesign.Shelf.expandedTopInset,
            width: expandedWidth,
            height: expandedHeight
        )

        return NotchGeometry(
            screen: screen,
            compactFrame: compactFrame.integral,
            expandedFrame: expandedFrame.integral,
            hasHardwareNotch: hasHardwareNotch,
            notchWidth: visualNotchWidth
        )
    }

    private static func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private static func detectedNotchWidth(on screen: NSScreen) -> CGFloat {
        guard #available(macOS 12.0, *) else { return 0 }
        guard screen.safeAreaInsets.top > 0 else { return 0 }

        let leftWidth = screen.auxiliaryTopLeftArea?.width ?? 0
        let rightWidth = screen.auxiliaryTopRightArea?.width ?? 0
        let width = screen.frame.width - leftWidth - rightWidth

        guard width > 80, width < 360 else { return 0 }
        return width
    }
}
