import AppKit
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Tsukimi

@MainActor
struct TsukimiTests {
    @Test func settingsDefaultsMatchMVP() async throws {
        let defaults = try makeDefaults()
        let settings = SettingsStore(defaults: defaults)

        #expect(settings.showShelfAfterCapture == true)
        #expect(settings.autoHideShelf == true)
        #expect(settings.autoHideDelay == 8)
        #expect(settings.maxUnpinnedScreenshots == 25)
        #expect(settings.deleteUnpinnedAfterHours == 24)
        #expect(settings.copyImageOnCapture == false)
    }

    @Test func manifestLoadsEmptyWhenAbsent() async throws {
        let fixture = try makeRepositoryFixture()

        try fixture.repository.load()

        #expect(fixture.repository.items.isEmpty)
    }

    @Test func addScreenshotPersistsMetadataAndReloads() async throws {
        let fixture = try makeRepositoryFixture(now: Date(timeIntervalSince1970: 100))
        let imageURL = try makePNG(in: fixture.rootURL)

        try fixture.repository.load()
        try fixture.repository.addCapturedScreenshot(at: imageURL)

        #expect(fixture.repository.items.count == 1)
        let item = try #require(fixture.repository.items.first)
        #expect(item.filePath == imageURL.path)
        #expect(item.fileSizeBytes > 0)
        #expect(item.width > 0)
        #expect(item.height > 0)
        #expect(item.captureBackend == nil)
        #expect(item.captureScale == nil)
        #expect(item.displayIDs == nil)
        #expect(item.isPinned == false)
        #expect(item.expiresAt == Date(timeIntervalSince1970: 100 + 24 * 60 * 60))

        let reloaded = fixture.makeRepository(now: Date(timeIntervalSince1970: 200))
        try reloaded.load()
        #expect(reloaded.items == fixture.repository.items)
    }

    @Test func addCaptureResultPersistsNativeMetadataAndReloads() async throws {
        let fixture = try makeRepositoryFixture(now: Date(timeIntervalSince1970: 100))
        let imageURL = try makePNG(in: fixture.rootURL)
        let result = ScreenCaptureResult(
            fileURL: imageURL,
            backend: .native,
            pixelSize: CGSize(width: 128, height: 64),
            scale: 2,
            displayIDs: [42, 99],
            selectedRect: CGRect(x: 10, y: 20, width: 64, height: 32)
        )

        try fixture.repository.load()
        try fixture.repository.addCapturedScreenshot(result)

        let item = try #require(fixture.repository.items.first)
        #expect(item.filePath == imageURL.path)
        #expect(item.width == 128)
        #expect(item.height == 64)
        #expect(item.captureBackend == .native)
        #expect(item.captureScale == 2)
        #expect(item.displayIDs == [42, 99])

        let reloaded = fixture.makeRepository(now: Date(timeIntervalSince1970: 200))
        try reloaded.load()
        #expect(reloaded.items == fixture.repository.items)
    }

    @Test func screenshotFilenamesUseTsukimiPrefix() async throws {
        let fixture = try makeRepositoryFixture()

        let fileURL = try fixture.storage.makeScreenshotFileURL()

        #expect(fileURL.lastPathComponent.hasPrefix("\(AppBrand.screenshotFilenamePrefix)-"))
    }

    @Test func dragProviderExposesFileURLAndImageRepresentations() async throws {
        let fixture = try makeRepositoryFixture()
        let imageURL = try makePNG(in: fixture.rootURL)
        let item = try fixture.storage.metadata(
            for: imageURL,
            now: Date(timeIntervalSince1970: 100),
            lifetime: 60
        )

        let provider = DragItemProvider.provider(for: item)
        let identifiers = Set(provider.registeredTypeIdentifiers)

        #expect(identifiers.contains(UTType.fileURL.identifier))
        #expect(identifiers.contains(UTType.png.identifier))
        #expect(identifiers.contains(UTType.image.identifier))
        #expect(identifiers.contains(UTType.tiff.identifier))
    }

    @Test func legacyManifestWithoutCaptureMetadataStillLoads() async throws {
        let fixture = try makeRepositoryFixture()
        let imageURL = try makePNG(in: fixture.rootURL)
        let id = UUID()

        try fixture.storage.prepareDirectories()
        let manifest = """
        {
          "items": [
            {
              "id": "\(id.uuidString)",
              "filePath": "\(imageURL.path)",
              "createdAt": "1970-01-01T00:00:00Z",
              "width": 20,
              "height": 12,
              "fileSizeBytes": 100,
              "isPinned": false,
              "expiresAt": null,
              "lastDraggedAt": null
            }
          ]
        }
        """
        try Data(manifest.utf8).write(to: fixture.storage.manifestURL)

        try fixture.repository.load()

        let item = try #require(fixture.repository.items.first)
        #expect(item.id == id)
        #expect(item.captureBackend == nil)
        #expect(item.captureScale == nil)
        #expect(item.displayIDs == nil)
    }

    @Test func deleteRemovesEntryAndFile() async throws {
        let fixture = try makeRepositoryFixture()
        let imageURL = try makePNG(in: fixture.rootURL)

        try fixture.repository.load()
        try fixture.repository.addCapturedScreenshot(at: imageURL)
        let item = try #require(fixture.repository.items.first)

        try fixture.repository.delete(item)

        #expect(fixture.repository.items.isEmpty)
        #expect(FileManager.default.fileExists(atPath: imageURL.path) == false)
    }

    @Test func clearUnpinnedKeepsPinnedScreenshots() async throws {
        let fixture = try makeRepositoryFixture()
        let firstURL = try makePNG(in: fixture.rootURL, name: "first.png")
        let secondURL = try makePNG(in: fixture.rootURL, name: "second.png")

        try fixture.repository.load()
        try fixture.repository.addCapturedScreenshot(at: firstURL)
        try fixture.repository.addCapturedScreenshot(at: secondURL)

        let pinned = try #require(fixture.repository.items.first)
        try fixture.repository.togglePinned(pinned)
        try fixture.repository.clearUnpinned()

        #expect(fixture.repository.items.count == 1)
        #expect(fixture.repository.items[0].id == pinned.id)
        #expect(fixture.repository.items[0].isPinned)
    }

    @Test func cleanupDeletesExpiredUnpinnedAndKeepsPinned() async throws {
        var currentDate = Date(timeIntervalSince1970: 100)
        let fixture = try makeRepositoryFixture(now: currentDate)
        let expiredURL = try makePNG(in: fixture.rootURL, name: "expired.png")
        let pinnedURL = try makePNG(in: fixture.rootURL, name: "pinned.png")

        try fixture.repository.load()
        try fixture.repository.addCapturedScreenshot(at: expiredURL)
        try fixture.repository.addCapturedScreenshot(at: pinnedURL)
        let pinned = try #require(fixture.repository.items.first)
        try fixture.repository.togglePinned(pinned)

        currentDate = Date(timeIntervalSince1970: 100 + 25 * 60 * 60)
        let cleanupRepository = fixture.makeRepository(now: currentDate)
        try cleanupRepository.load()
        try cleanupRepository.cleanupExpired()

        #expect(cleanupRepository.items.count == 1)
        #expect(cleanupRepository.items[0].id == pinned.id)
        #expect(FileManager.default.fileExists(atPath: expiredURL.path) == false)
        #expect(FileManager.default.fileExists(atPath: pinnedURL.path) == true)
    }

    private func makeRepositoryFixture(now: Date = Date(timeIntervalSince1970: 0)) throws -> RepositoryFixture {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TsukimiTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let defaults = try makeDefaults()
        let settings = SettingsStore(defaults: defaults)
        let storage = FileStorageService(applicationSupportURL: rootURL)
        let repository = ScreenshotRepository(storage: storage, settings: settings, now: { now })
        return RepositoryFixture(rootURL: rootURL, settings: settings, storage: storage, repository: repository)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "TsukimiTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makePNG(in rootURL: URL, name: String = "screenshot.png") throws -> URL {
        let directory = rootURL.appendingPathComponent("screenshots", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)

        let image = NSImage(size: NSSize(width: 20, height: 12))
        image.lockFocus()
        NSColor.systemGreen.setFill()
        NSRect(x: 0, y: 0, width: 20, height: 12).fill()
        image.unlockFocus()

        let representation = try #require(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        let data = try #require(representation.representation(using: .png, properties: [:]))
        try data.write(to: url)
        return url
    }
}

@MainActor
private struct RepositoryFixture {
    let rootURL: URL
    let settings: SettingsStore
    let storage: FileStorageService
    let repository: ScreenshotRepository

    func makeRepository(now: Date) -> ScreenshotRepository {
        ScreenshotRepository(storage: storage, settings: settings, now: { now })
    }
}
