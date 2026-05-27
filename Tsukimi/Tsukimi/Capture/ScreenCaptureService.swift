import CoreGraphics
import Foundation
import ImageIO

protocol ScreenCaptureService {
    func captureArea() async throws -> ScreenCaptureResult
    func captureArea(rect: CGRect?) async throws -> ScreenCaptureResult
}

extension ScreenCaptureService {
    func captureArea(rect: CGRect?) async throws -> ScreenCaptureResult {
        try await captureArea()
    }
}

enum CaptureBackend: String, Codable, Equatable {
    case native
    case screencaptureCLI = "screencapture-cli"
}

struct ScreenCaptureResult: Equatable {
    let fileURL: URL
    let backend: CaptureBackend
    let pixelSize: CGSize
    let scale: CGFloat
    let displayIDs: [CGDirectDisplayID]
    let selectedRect: CGRect?
}

enum ScreenCaptureError: Error, Equatable {
    case cancelled
    case failed(Int32)
    case missingOutput
    case couldNotLaunch
    case nativeCaptureFailed
    case screenRecordingPermissionRequired
}

struct ScreencaptureScreenCaptureService: ScreenCaptureService {
    private let storage: FileStorageService

    init(storage: FileStorageService) {
        self.storage = storage
    }

    func captureArea() async throws -> ScreenCaptureResult {
        try await captureArea(rect: nil)
    }

    func captureArea(rect: CGRect?) async throws -> ScreenCaptureResult {
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenCaptureError.screenRecordingPermissionRequired
        }

        let outputURL = try storage.makeScreenshotFileURL()

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

            if let rect = rect {
                let r = rect.standardized
                process.arguments = ["-R\(r.origin.x),\(r.origin.y),\(r.width),\(r.height)", "-x", outputURL.path]
            } else {
                process.arguments = ["-i", "-s", "-x", outputURL.path]
            }

            process.terminationHandler = { process in
                let status = process.terminationStatus

                if status == 0, FileManager.default.fileExists(atPath: outputURL.path) {
                    let image = CGImageSourceCreateWithURL(outputURL as CFURL, nil)
                        .flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
                    let pixelSize = image.map { CGSize(width: $0.width, height: $0.height) } ?? .zero
                    continuation.resume(returning: ScreenCaptureResult(
                        fileURL: outputURL,
                        backend: .screencaptureCLI,
                        pixelSize: pixelSize,
                        scale: 1,
                        displayIDs: [],
                        selectedRect: rect?.standardized
                    ))
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
