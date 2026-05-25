import SwiftUI

enum BagEndDesign {
    enum ColorToken {
        static let brandDeep = Color(hex: 0x1F2430)
        static let brandPrimary = Color(hex: 0x5B86F7)
        static let brandPrimaryHover = Color(hex: 0x4A74E6)
        static let brandAccent = Color(hex: 0xF5B548)
        static let brandAccentHover = Color(hex: 0xE5A437)
        static let brandSecondary = Color(hex: 0x5A6270)
        static let muted = Color(hex: 0x8A92A1)
        static let graphite = Color(hex: 0x2C313D)

        static let primaryBackground = Color(hex: 0xF4F5F7)
        static let secondaryBackground = Color(hex: 0xECEEF2)
        static let surface = Color(hex: 0xFFFFFF)
        static let border = Color(hex: 0xD8DCE3)
        static let accentBlueSoft = Color(hex: 0xDCE6FF)
        static let accentAmberSoft = Color(hex: 0xFFE9BF)

        static let surfaceGreen = accentBlueSoft.opacity(0.72)
        static let surfaceCard = surface.opacity(0.96)
        static let shelfSurface = primaryBackground
        static let shelfSurfaceDeep = secondaryBackground
        static let shelfBorder = border.opacity(0.82)
        static let slideTrack = border.opacity(0.92)
        static let wallpaperA = primaryBackground
        static let wallpaperB = secondaryBackground
        static let wallpaperWarm = accentAmberSoft

        static let textPrimary = brandDeep
        static let textSecondary = brandSecondary
    }

    enum Shelf {
        static let width: CGFloat = 940
        static let height: CGFloat = 430
        static let cornerRadius: CGFloat = 28
        static let outerPadding: CGFloat = 24
        static let topOffset: CGFloat = 24
        static let expandedTopInset: CGFloat = 8
        static let notchWidth: CGFloat = 180
        static let notchHeight: CGFloat = 34
        static let handleWidth: CGFloat = 220
        static let handleHeight: CGFloat = 46
        static let iconSize: CGFloat = 34
    }

    enum Card {
        static let width: CGFloat = 148
        static let height: CGFloat = 136
        static let cornerRadius: CGFloat = 13
        static let thumbnailWidth: CGFloat = 128
        static let thumbnailHeight: CGFloat = 72
        static let thumbnailCornerRadius: CGFloat = 9
        static let spacing: CGFloat = 18
        static let rowSpacing: CGFloat = 30
    }

    enum Control {
        static let height: CGFloat = 28
        static let cornerRadius: CGFloat = 14
        static let captureWidth: CGFloat = 116
        static let clearUnpinnedWidth: CGFloat = 122
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
