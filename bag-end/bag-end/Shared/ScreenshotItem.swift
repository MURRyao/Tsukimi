import Foundation

struct ScreenshotItem: Identifiable, Codable, Equatable {
    let id: UUID
    var filePath: String
    var createdAt: Date
    var width: Int
    var height: Int
    var fileSizeBytes: Int
    var isPinned: Bool
    var expiresAt: Date?
    var lastDraggedAt: Date?

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}
