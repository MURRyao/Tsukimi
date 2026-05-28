import AppKit
import SwiftUI

struct TsukimiShelfView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var repository: ScreenshotRepository
    @ObservedObject var settings: SettingsStore
    let closeAction: () -> Void

    init(
        appState: AppState,
        repository: ScreenshotRepository,
        settings: SettingsStore,
        closeAction: @escaping () -> Void = {}
    ) {
        self.appState = appState
        self.repository = repository
        self.settings = settings
        self.closeAction = closeAction
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: TsukimiDesign.Shelf.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            TsukimiDesign.ColorToken.shelfSurface,
                            TsukimiDesign.ColorToken.shelfSurfaceDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TsukimiDesign.Shelf.cornerRadius, style: .continuous)
                        .stroke(TsukimiDesign.ColorToken.shelfBorder, lineWidth: 1.5)
                        .padding(1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TsukimiDesign.Shelf.cornerRadius - 7, style: .continuous)
                        .stroke(.white.opacity(0.72), lineWidth: 1)
                        .padding(10)
                )
                .shadow(color: TsukimiDesign.ColorToken.graphite.opacity(0.18), radius: 28, y: 18)

            VStack(alignment: .leading, spacing: 18) {
                ShelfHeaderView(
                    count: repository.items.count,
                    autoHideDelay: Int(settings.autoHideDelay),
                    captureAction: appState.captureArea,
                    clearAction: appState.clearUnpinnedScreenshots,
                    closeAction: closeAction
                )

                if repository.items.isEmpty {
                    EmptyShelfView(captureAction: appState.captureArea)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        ScreenshotGridView(
                            items: repository.items,
                            appState: appState
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.trailing, -10)
                }
            }
            .padding(.horizontal, TsukimiDesign.Shelf.outerPadding)
            .padding(.top, 18)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Capsule(style: .continuous)
                .fill(TsukimiDesign.ColorToken.muted.opacity(0.28))
                .frame(width: 86, height: 4)
                .padding(.top, 8)
        }
        .frame(width: TsukimiDesign.Shelf.width, height: TsukimiDesign.Shelf.height)
    }
}

private struct ShelfHeaderView: View {
    let count: Int
    let autoHideDelay: Int
    let captureAction: () -> Void
    let clearAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AppIconMark()

            VStack(alignment: .leading, spacing: 2) {
                Text(AppBrand.displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(TsukimiDesign.ColorToken.textPrimary)

                Text("\(count) temporary screenshots · local only · auto-hide in \(autoHideDelay)s")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TsukimiDesign.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 24)

            ShelfButton("Capture Area", width: TsukimiDesign.Control.captureWidth, prominent: true, action: captureAction)
            ShelfButton("Clear Unpinned", width: TsukimiDesign.Control.clearUnpinnedWidth, action: clearAction)
            Button(action: closeAction) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(TsukimiDesign.ColorToken.textPrimary)
            .background(TsukimiDesign.ColorToken.surfaceGreen, in: Circle())
            .help("Collapse")
        }
        .frame(height: 42)
    }
}

private struct AppIconMark: View {
    var body: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .scaledToFit()
            .shadow(color: TsukimiDesign.ColorToken.graphite.opacity(0.14), radius: 4, y: 2)
            .frame(width: TsukimiDesign.Shelf.iconSize, height: TsukimiDesign.Shelf.iconSize)
    }
}

private struct ShelfButton: View {
    let title: String
    let width: CGFloat
    let prominent: Bool
    let action: () -> Void

    init(_ title: String, width: CGFloat, prominent: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.prominent = prominent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(width: width, height: TsukimiDesign.Control.height)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? .white : TsukimiDesign.ColorToken.textPrimary)
        .background(
            Capsule(style: .continuous)
                .fill(prominent ? TsukimiDesign.ColorToken.brandPrimary : TsukimiDesign.ColorToken.surfaceGreen)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    prominent ? TsukimiDesign.ColorToken.brandPrimaryHover.opacity(0.5) : TsukimiDesign.ColorToken.border,
                    lineWidth: 1
                )
        )
    }
}

private struct ScreenshotGridView: View {
    let items: [ScreenshotItem]
    @ObservedObject var appState: AppState

    private let columns = Array(
        repeating: GridItem(
            .flexible(minimum: TsukimiDesign.Card.width, maximum: .infinity),
            spacing: TsukimiDesign.Card.spacing,
            alignment: .center
        ),
        count: 5
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: TsukimiDesign.Card.rowSpacing) {
            ForEach(items) { item in
                ScreenshotCardView(
                    item: item,
                    deleteAction: {
                        appState.deleteScreenshot(item)
                    },
                    pinAction: {
                        appState.togglePin(item)
                    },
                    dragStarted: {
                        appState.updateLastDragged(item)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }
}

private struct EmptyShelfView: View {
    let captureAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("No screenshots in \(AppBrand.displayName)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(TsukimiDesign.ColorToken.textPrimary)

            Text("Press the capture hotkey. New screenshots stay off Desktop and appear here temporarily.")
                .font(.system(size: 13))
                .foregroundStyle(TsukimiDesign.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            ShelfButton("Capture Area", width: TsukimiDesign.Control.captureWidth, prominent: true, action: captureAction)
        }
    }
}
