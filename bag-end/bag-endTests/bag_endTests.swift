import AppKit
import Foundation
import Testing
@testable import bag_end

@MainActor
struct bag_endTests {
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
        #expect(item.isPinned == false)
        #expect(item.expiresAt == Date(timeIntervalSince1970: 100 + 24 * 60 * 60))

        let reloaded = fixture.makeRepository(now: Date(timeIntervalSince1970: 200))
        try reloaded.load()
        #expect(reloaded.items == fixture.repository.items)
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
            .appendingPathComponent("BagEndTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let defaults = try makeDefaults()
        let settings = SettingsStore(defaults: defaults)
        let storage = FileStorageService(applicationSupportURL: rootURL)
        let repository = ScreenshotRepository(storage: storage, settings: settings, now: { now })
        return RepositoryFixture(rootURL: rootURL, settings: settings, storage: storage, repository: repository)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "BagEndTests-\(UUID().uuidString)"
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
