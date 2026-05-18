import AppKit

extension NSImage {
    /// Creates a thumbnail Data (PNG) of the image, fitting within maxDimension.
    func thumbnailData(maxDimension: CGFloat = AppConstants.thumbnailMaxDimension) -> Data? {
        let sourceSize = self.size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }

        let scale: CGFloat
        if sourceSize.width > sourceSize.height {
            scale = maxDimension / sourceSize.width
        } else {
            scale = maxDimension / sourceSize.height
        }

        let targetSize = NSSize(
            width: sourceSize.width * min(scale, 1.0),
            height: sourceSize.height * min(scale, 1.0)
        )

        let thumbnailImage = NSImage(size: targetSize)
        thumbnailImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1.0
        )
        thumbnailImage.unlockFocus()

        guard let tiffData = thumbnailImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }

        return bitmapRep.representation(using: .png, properties: [.compressionFactor: 0.8])
    }
}
