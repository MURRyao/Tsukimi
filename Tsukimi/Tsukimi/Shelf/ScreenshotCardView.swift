import AppKit
import SwiftUI

struct ScreenshotCardView: View {
    let item: ScreenshotItem
    let deleteAction: () -> Void
    let pinAction: () -> Void
    let dragStarted: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ScreenshotThumbnailView(fileURL: item.fileURL)
                    .frame(width: TsukimiDesign.Card.thumbnailWidth, height: TsukimiDesign.Card.thumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: TsukimiDesign.Card.thumbnailCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TsukimiDesign.Card.thumbnailCornerRadius, style: .continuous)
                            .stroke(TsukimiDesign.ColorToken.border.opacity(0.75), lineWidth: 1)
                    )

                Button(action: deleteAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(TsukimiDesign.ColorToken.muted)
                        .frame(width: 20, height: 20)
                        .background(.white.opacity(0.9), in: Circle())
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0.7)
                .offset(x: 6, y: -6)

                if item.isPinned {
                    Circle()
                        .fill(TsukimiDesign.ColorToken.brandPrimary)
                        .frame(width: 8, height: 8)
                        .offset(x: -86, y: 8)
                }
            }

            Text(displayTitle)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(TsukimiDesign.ColorToken.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(height: 17, alignment: .bottom)
                .padding(.top, 6)

            Text(metadataText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(TsukimiDesign.ColorToken.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(height: 14, alignment: .top)
                .padding(.top, 1)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(width: TsukimiDesign.Card.width, height: TsukimiDesign.Card.height, alignment: .topLeading)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: TsukimiDesign.Card.cornerRadius, style: .continuous)
                .fill(TsukimiDesign.ColorToken.surfaceCard)
                .shadow(color: TsukimiDesign.ColorToken.graphite.opacity(0.09), radius: 9, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TsukimiDesign.Card.cornerRadius, style: .continuous)
                .stroke(TsukimiDesign.ColorToken.border.opacity(0.72), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: TsukimiDesign.Card.cornerRadius, style: .continuous))
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin", action: pinAction)
            Button("Copy Image") {
                DragItemProvider.copyImageToPasteboard(for: item.fileURL)
            }
            Button("Copy File") {
                DragItemProvider.copyFileToPasteboard(for: item.fileURL)
            }
            Button("Save As...") {
                DragItemProvider.saveImageAs(fileURL: item.fileURL, suggestedName: item.fileURL.lastPathComponent)
            }
            Button("Delete", action: deleteAction)
        }
        .onDrag {
            dragStarted()
            return DragItemProvider.provider(for: item)
        }
    }

    private var displayTitle: String {
        item.fileURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "\(AppBrand.screenshotFilenamePrefix)-", with: "")
            .prefix(24)
            .description
    }

    private var metadataText: String {
        if item.lastDraggedAt != nil {
            return "file URL + PNG"
        }

        let dimensions = item.width > 0 && item.height > 0 ? "\(item.width)x\(item.height)" : "PNG"
        let backend = item.captureBackend?.rawValue ?? "legacy"
        return "\(dimensions) · \(backend) · \(relativeAge)"
    }

    private var relativeAge: String {
        let seconds = max(0, Int(Date().timeIntervalSince(item.createdAt)))
        if seconds < 60 {
            return "\(seconds)s"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) min"
        }

        return "\(minutes / 60)h"
    }
}

@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, NSImage>()

    private init() {
        cache.countLimit = 100
    }

    func image(for fileURL: URL) -> NSImage? {
        cache.object(forKey: fileURL as NSURL)
    }

    func setImage(_ image: NSImage, for fileURL: URL) {
        cache.setObject(image, forKey: fileURL as NSURL)
    }
}

private struct ScreenshotThumbnailView: View {
    let fileURL: URL

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            TsukimiDesign.ColorToken.accentBlueSoft.opacity(0.95),
                            TsukimiDesign.ColorToken.wallpaperWarm.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 4) {
                            Circle().fill(.red.opacity(0.75)).frame(width: 5, height: 5)
                            Circle().fill(.yellow.opacity(0.75)).frame(width: 5, height: 5)
                            Circle().fill(.green.opacity(0.75)).frame(width: 5, height: 5)
                        }

                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.78)).frame(width: 52, height: 5)
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.48)).frame(width: 72, height: 5)
                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.38)).frame(width: 58, height: 5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                }
            }
        }
        .task(id: fileURL) {
            if let cached = ThumbnailCache.shared.image(for: fileURL) {
                image = cached
                return
            }
            let loaded = await Task.detached {
                NSImage(contentsOf: fileURL)
            }.value
            if let loaded {
                ThumbnailCache.shared.setImage(loaded, for: fileURL)
                image = loaded
            }
        }
    }
}
