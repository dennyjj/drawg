import AppKit

class StorageManager {
    private let baseDirectory: URL
    private let capturesDirectory: URL

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        baseDirectory = home.appendingPathComponent(".drawg")
        capturesDirectory = baseDirectory.appendingPathComponent("captures")
        ensureDirectoryExists()
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: capturesDirectory, withIntermediateDirectories: true)
    }

    func saveImage(_ image: CGImage, format: ImageFormat = .png) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = formatter.string(from: Date()) + format.fileExtension
        let url = capturesDirectory.appendingPathComponent(filename)

        guard let data = ImageExporter.imageData(from: image, format: format) else { return nil }

        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    func listCaptures() -> [CaptureFile] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: capturesDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return files
            .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
            .compactMap { url -> CaptureFile? in
                let resources = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                return CaptureFile(
                    url: url,
                    createdAt: resources?.creationDate ?? Date(),
                    fileSize: resources?.fileSize ?? 0
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func deleteCapture(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func thumbnail(for url: URL, maxSize: CGFloat = 200) -> NSImage? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        let ratio = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        return thumbnail
    }
}

struct CaptureFile {
    let url: URL
    let createdAt: Date
    let fileSize: Int
}

enum ImageFormat: String {
    case png
    case jpeg

    var fileExtension: String {
        switch self {
        case .png: return ".png"
        case .jpeg: return ".jpg"
        }
    }

    var utType: String {
        switch self {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        }
    }
}
