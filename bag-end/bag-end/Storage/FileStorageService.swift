import AppKit
import Foundation

struct FileStorageService {
    let applicationSupportURL: URL
    private let legacyApplicationSupportURL: URL?

    var screenshotsDirectory: URL {
        applicationSupportURL.appendingPathComponent("screenshots", isDirectory: true)
    }

    var manifestURL: URL {
        applicationSupportURL.appendingPathComponent("manifest.json")
    }

    init(applicationSupportURL: URL? = nil, legacyApplicationSupportURL: URL? = nil) {
        if let applicationSupportURL {
            self.applicationSupportURL = applicationSupportURL
            self.legacyApplicationSupportURL = legacyApplicationSupportURL
        } else {
            let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.applicationSupportURL = baseURL.appendingPathComponent(AppBrand.storageDirectoryName, isDirectory: true)
            self.legacyApplicationSupportURL = baseURL.appendingPathComponent(AppBrand.legacyStorageDirectoryName, isDirectory: true)
        }
    }

    func prepareDirectories() throws {
        try migrateLegacyStorageIfNeeded()
        try FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
    }

    func makeScreenshotFileURL(id: UUID = UUID()) throws -> URL {
        try prepareDirectories()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let safeDate = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return screenshotsDirectory.appendingPathComponent("\(AppBrand.screenshotFilenamePrefix)-\(safeDate)-\(id.uuidString).png")
    }

    func metadata(
        for fileURL: URL,
        id: UUID = UUID(),
        now: Date,
        lifetime: TimeInterval,
        captureResult: ScreenCaptureResult? = nil
    ) throws -> ScreenshotItem {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        let image = NSImage(contentsOf: fileURL)
        let pixelSize = captureResult?.pixelSize ?? image?.pixelSize ?? .zero

        return ScreenshotItem(
            id: id,
            filePath: fileURL.path,
            createdAt: now,
            width: Int(pixelSize.width),
            height: Int(pixelSize.height),
            fileSizeBytes: fileSize,
            captureBackend: captureResult?.backend,
            captureScale: captureResult.map { Double($0.scale) },
            displayIDs: captureResult?.displayIDs,
            isPinned: false,
            expiresAt: now.addingTimeInterval(lifetime),
            lastDraggedAt: nil
        )
    }

    private func migrateLegacyStorageIfNeeded() throws {
        guard let legacyApplicationSupportURL,
              legacyApplicationSupportURL != applicationSupportURL,
              FileManager.default.fileExists(atPath: legacyApplicationSupportURL.path),
              !FileManager.default.fileExists(atPath: applicationSupportURL.path) else {
            return
        }

        try FileManager.default.moveItem(at: legacyApplicationSupportURL, to: applicationSupportURL)
    }
}

private extension NSImage {
    var pixelSize: CGSize {
        guard let representation = representations.first else {
            return size
        }

        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }
}
