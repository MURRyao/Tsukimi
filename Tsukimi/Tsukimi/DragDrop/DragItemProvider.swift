import AppKit
import UniformTypeIdentifiers

enum DragItemProvider {
    static func provider(for item: ScreenshotItem) -> NSItemProvider {
        let fileURL = item.fileURL
        let provider = NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()
        provider.suggestedName = fileURL.deletingPathExtension().lastPathComponent

        provider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
            Task.detached {
                let data = try? Data(contentsOf: fileURL)
                completion(data, nil)
            }
            return nil
        }

        provider.registerDataRepresentation(forTypeIdentifier: UTType.image.identifier, visibility: .all) { completion in
            Task.detached {
                let data = try? Data(contentsOf: fileURL)
                completion(data, nil)
            }
            return nil
        }

        provider.registerDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { completion in
            completion(fileURL.absoluteString.data(using: .utf8), nil)
            return nil
        }

        provider.registerDataRepresentation(forTypeIdentifier: UTType.tiff.identifier, visibility: .all) { completion in
            Task.detached {
                let image = NSImage(contentsOf: fileURL)
                let tiffData = image?.tiffRepresentation
                completion(tiffData, nil)
            }
            return nil
        }

        return provider
    }

    static func copyImageToPasteboard(for fileURL: URL) {
        guard let image = NSImage(contentsOf: fileURL) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    static func copyFileToPasteboard(for fileURL: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([fileURL as NSURL])
    }

    static func saveImageAs(fileURL: URL, suggestedName: String? = nil) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedName ?? fileURL.lastPathComponent

        guard panel.runModal() == .OK, let destinationURL = panel.url else { return }

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        } catch {
            NSSound.beep()
        }
    }
}
