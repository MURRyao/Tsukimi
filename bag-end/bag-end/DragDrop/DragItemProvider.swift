import AppKit

enum DragItemProvider {
    static func provider(for item: ScreenshotItem) -> NSItemProvider {
        let fileURL = item.fileURL
        let provider = NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()

        if let data = try? Data(contentsOf: fileURL) {
            provider.registerDataRepresentation(forTypeIdentifier: "public.png", visibility: .all) { completion in
                completion(data, nil)
                return nil
            }
        }

        if let image = NSImage(contentsOf: fileURL), let tiffData = image.tiffRepresentation {
            provider.registerDataRepresentation(forTypeIdentifier: "public.tiff", visibility: .all) { completion in
                completion(tiffData, nil)
                return nil
            }
        }

        return provider
    }

    static func copyImageToPasteboard(for fileURL: URL) {
        guard let image = NSImage(contentsOf: fileURL) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}
