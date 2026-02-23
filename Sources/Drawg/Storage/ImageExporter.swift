import AppKit

class ImageExporter {
    static func imageData(from cgImage: CGImage, format: ImageFormat) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
    }

    static func flattenAnnotations(baseImage: CGImage, annotations: [Annotation], canvasSize: NSSize) -> CGImage? {
        let width = baseImage.width
        let height = baseImage.height
        let scaleX = CGFloat(width) / canvasSize.width
        let scaleY = CGFloat(height) / canvasSize.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Draw base image
        context.draw(baseImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Create NSGraphicsContext for drawing annotations
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        // Scale the context to map from canvas coordinates to pixel coordinates
        let transform = NSAffineTransform()
        transform.scaleX(by: scaleX, yBy: scaleY)
        transform.concat()

        for annotation in annotations {
            annotation.draw()
        }

        NSGraphicsContext.restoreGraphicsState()

        return context.makeImage()
    }

    static func copyToClipboard(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        pasteboard.writeObjects([nsImage])
    }
}
