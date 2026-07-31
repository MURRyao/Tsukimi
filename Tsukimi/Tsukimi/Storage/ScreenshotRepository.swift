import Combine
import Foundation

final class ScreenshotRepository: ObservableObject {
    @Published private(set) var items: [ScreenshotItem] = []
    @Published var lastLoadWarning: String?

    private let storage: FileStorageService
    private let settings: SettingsStore
    private let now: () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        storage: FileStorageService,
        settings: SettingsStore,
        now: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.settings = settings
        self.now = now
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws {
        try storage.prepareDirectories()

        guard FileManager.default.fileExists(atPath: storage.manifestURL.path) else {
            items = []
            return
        }

        let data = try Data(contentsOf: storage.manifestURL)

        do {
            let manifest = try decoder.decode(ScreenshotManifest.self, from: data)
            var loadedItems = sorted(manifest.items)
            let missing = loadedItems.filter { !FileManager.default.fileExists(atPath: $0.filePath) }
            if !missing.isEmpty {
                loadedItems.removeAll { item in missing.contains(where: { $0.id == item.id }) }
                items = loadedItems
                try save()
            } else {
                items = loadedItems
            }
        } catch {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let backupURL = storage.manifestURL.deletingLastPathComponent()
                .appendingPathComponent("manifest.backup.\(timestamp).json")
            try? FileManager.default.moveItem(at: storage.manifestURL, to: backupURL)
            items = []
            lastLoadWarning = "Your screenshot list was corrupted and has been reset. A backup was saved."
        }
    }

    func addCapturedScreenshot(at fileURL: URL) throws {
        let item = try storage.metadata(
            for: fileURL,
            now: now(),
            lifetime: settings.unpinnedLifetime
        )
        items.insert(item, at: 0)
        try enforceMaxUnpinnedCount()
        try save()
    }

    func addCapturedScreenshot(_ captureResult: ScreenCaptureResult) throws {
        let item = try storage.metadata(
            for: captureResult.fileURL,
            now: now(),
            lifetime: settings.unpinnedLifetime,
            captureResult: captureResult
        )
        items.insert(item, at: 0)
        try enforceMaxUnpinnedCount()
        try save()
    }

    func delete(_ item: ScreenshotItem) throws {
        items.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: item.fileURL)
        try save()
    }

    func clearUnpinned() throws {
        let unpinned = items.filter { !$0.isPinned }
        items.removeAll { !$0.isPinned }

        for item in unpinned {
            try? FileManager.default.removeItem(at: item.fileURL)
        }

        try save()
    }

    func togglePinned(_ item: ScreenshotItem) throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        items[index].expiresAt = items[index].isPinned ? nil : now().addingTimeInterval(settings.unpinnedLifetime)
        try save()
    }

    func updateLastDragged(_ item: ScreenshotItem) throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].lastDraggedAt = now()
        try save()
    }

    func cleanupExpired() throws {
        let currentDate = now()
        let expired = items.filter { item in
            guard !item.isPinned, let expiresAt = item.expiresAt else { return false }
            return expiresAt <= currentDate
        }

        guard !expired.isEmpty else { return }

        items.removeAll { item in
            expired.contains(where: { $0.id == item.id })
        }

        for item in expired {
            try? FileManager.default.removeItem(at: item.fileURL)
        }

        try save()
    }

    func applyStoragePolicies() throws {
        var changed = false

        for index in items.indices {
            if !items[index].isPinned {
                let newExpiresAt = items[index].createdAt.addingTimeInterval(settings.unpinnedLifetime)
                if items[index].expiresAt != newExpiresAt {
                    items[index].expiresAt = newExpiresAt
                    changed = true
                }
            }
        }

        let countBeforeEnforce = items.count
        try enforceMaxUnpinnedCount()
        if items.count != countBeforeEnforce {
            changed = true
        }

        let countBeforeCleanup = items.count
        try cleanupExpired()

        if changed && items.count == countBeforeCleanup {
            try save()
        }
    }

    private func enforceMaxUnpinnedCount() throws {
        let unpinned = items.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
        guard unpinned.count > settings.maxUnpinnedScreenshots else { return }

        let overflow = unpinned.dropFirst(settings.maxUnpinnedScreenshots)
        let overflowIDs = Set(overflow.map(\.id))
        items.removeAll { overflowIDs.contains($0.id) }

        for item in overflow {
            try? FileManager.default.removeItem(at: item.fileURL)
        }
    }

    private func save() throws {
        try storage.prepareDirectories()
        items = sorted(items)
        let data = try encoder.encode(ScreenshotManifest(items: items))
        try data.write(to: storage.manifestURL, options: .atomic)
    }

    private func sorted(_ values: [ScreenshotItem]) -> [ScreenshotItem] {
        values.sorted { $0.createdAt > $1.createdAt }
    }
}

private struct ScreenshotManifest: Codable {
    var items: [ScreenshotItem]
}
