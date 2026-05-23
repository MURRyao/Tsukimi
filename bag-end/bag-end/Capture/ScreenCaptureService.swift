import CoreGraphics
import Foundation

protocol ScreenCaptureService {
    func captureArea() async throws -> URL
}

enum ScreenCaptureError: Error, Equatable {
    case cancelled
    case failed(Int32)
    case missingOutput
    case couldNotLaunch
    case screenRecordingPermissionRequired
}

struct ScreencaptureScreenCaptureService: ScreenCaptureService {
    private let storage: FileStorageService

    init(storage: FileStorageService) {
        self.storage = storage
    }

    func captureArea() async throws -> URL {
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenCaptureError.screenRecordingPermissionRequired
        }

        let outputURL = try storage.makeScreenshotFileURL()

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-s", "-x", outputURL.path]

            process.terminationHandler = { process in
                let status = process.terminationStatus

                if status == 0, FileManager.default.fileExists(atPath: outputURL.path) {
                    continuation.resume(returning: outputURL)
                } else if status == 0 {
                    continuation.resume(throwing: ScreenCaptureError.missingOutput)
                } else if !FileManager.default.fileExists(atPath: outputURL.path) {
                    continuation.resume(throwing: ScreenCaptureError.cancelled)
                } else {
                    continuation.resume(throwing: ScreenCaptureError.failed(status))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ScreenCaptureError.couldNotLaunch)
            }
        }
    }
}
