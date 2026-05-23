import SwiftUI

enum BagEndDesign {
    enum ColorToken {
        static let brandDeep = Color(hex: 0x12351F)
        static let brandPrimary = Color(hex: 0x2E7D32)
        static let brandAccent = Color(hex: 0x43A047)
        static let brandSecondary = Color(hex: 0x55735B)

        static let surfaceGreen = Color(hex: 0xF4FFF5).opacity(0.78)
        static let surfaceCard = Color(hex: 0xF8FFF9).opacity(0.92)
        static let shelfSurface = Color(hex: 0x2F8D4C)
        static let shelfSurfaceDeep = Color(hex: 0x1F6F3B)
        static let shelfBorder = Color(hex: 0xBDE8C6).opacity(0.42)
        static let slideTrack = Color(hex: 0xD7EAD7).opacity(0.92)
        static let wallpaperA = Color(hex: 0xEEF8EF)
        static let wallpaperB = Color(hex: 0xD9ECD8)
        static let wallpaperWarm = Color(hex: 0xF5F1E6)

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
    }

    enum Control {
        static let height: CGFloat = 28
        static let cornerRadius: CGFloat = 14
        static let captureWidth: CGFloat = 116
        static let clearAllWidth: CGFloat = 82
        static let pinModeWidth: CGFloat = 86
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
