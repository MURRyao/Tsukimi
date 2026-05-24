import SwiftUI

struct BagEndShelfView: View {
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
            RoundedRectangle(cornerRadius: BagEndDesign.Shelf.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BagEndDesign.ColorToken.shelfSurface,
                            BagEndDesign.ColorToken.shelfSurfaceDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BagEndDesign.Shelf.cornerRadius, style: .continuous)
                        .stroke(BagEndDesign.ColorToken.shelfBorder, lineWidth: 1.5)
                        .padding(1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BagEndDesign.Shelf.cornerRadius - 7, style: .continuous)
                        .stroke(.white.opacity(0.13), lineWidth: 1)
                        .padding(10)
                )
                .shadow(color: .black.opacity(0.22), radius: 28, y: 18)

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
                            repository: repository
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.trailing, -10)
                }
            }
            .padding(.horizontal, BagEndDesign.Shelf.outerPadding)
            .padding(.top, 18)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Capsule(style: .continuous)
                .fill(.white.opacity(0.14))
                .frame(width: 86, height: 4)
                .padding(.top, 8)
        }
        .frame(width: BagEndDesign.Shelf.width, height: BagEndDesign.Shelf.height)
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
                Text("Bag End")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(BagEndDesign.ColorToken.textPrimary)

                Text("\(count) temporary screenshots · local only · auto-hide in \(autoHideDelay)s")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
            }

            Spacer(minLength: 24)

            ShelfButton("Capture Area", width: BagEndDesign.Control.captureWidth, prominent: true, action: captureAction)
            ShelfButton("Clear Unpinned", width: BagEndDesign.Control.clearUnpinnedWidth, action: clearAction)
            Button(action: closeAction) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(BagEndDesign.ColorToken.textPrimary)
            .background(BagEndDesign.ColorToken.surfaceGreen, in: Circle())
            .help("Collapse")
        }
        .frame(height: 42)
    }
}

private struct AppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BagEndDesign.ColorToken.brandDeep,
                            BagEndDesign.ColorToken.brandPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("B")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: BagEndDesign.Shelf.iconSize, height: BagEndDesign.Shelf.iconSize)
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
                .frame(width: width, height: BagEndDesign.Control.height)
        }
        .buttonStyle(.plain)
        .foregroundStyle(prominent ? .white : BagEndDesign.ColorToken.textPrimary)
        .background(
            Capsule(style: .continuous)
                .fill(prominent ? BagEndDesign.ColorToken.shelfSurfaceDeep.opacity(0.7) : BagEndDesign.ColorToken.surfaceGreen)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(.white.opacity(prominent ? 0.16 : 0.28), lineWidth: 1)
        )
    }
}

private struct ScreenshotGridView: View {
    let items: [ScreenshotItem]
    @ObservedObject var repository: ScreenshotRepository

    private let columns = Array(
        repeating: GridItem(
            .flexible(minimum: BagEndDesign.Card.width, maximum: .infinity),
            spacing: BagEndDesign.Card.spacing,
            alignment: .center
        ),
        count: 5
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: BagEndDesign.Card.rowSpacing) {
            ForEach(items) { item in
                ScreenshotCardView(
                    item: item,
                    deleteAction: {
                        try? repository.delete(item)
                    },
                    pinAction: {
                        try? repository.togglePinned(item)
                    },
                    dragStarted: {
                        try? repository.updateLastDragged(item)
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
            Text("No screenshots in Bag End")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(BagEndDesign.ColorToken.textPrimary)

            Text("Press the capture hotkey. New screenshots stay off Desktop and appear here temporarily.")
                .font(.system(size: 13))
                .foregroundStyle(BagEndDesign.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            ShelfButton("Capture Area", width: BagEndDesign.Control.captureWidth, prominent: true, action: captureAction)
        }
    }
}
