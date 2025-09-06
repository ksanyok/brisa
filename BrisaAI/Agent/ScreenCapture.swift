import Foundation
import CoreGraphics
import AppKit

final class ScreenCapture {
    static let shared = ScreenCapture()
    private init() {}

    func snapshotActiveScreen() -> NSImage? {
        // Снимок всего экрана (основного)
        let rect = NSScreen.main?.frame ?? .zero
        guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution]) else { return nil }
        return NSImage(cgImage: cgImage, size: rect.size)
    }

    func snapshotPNGData() -> Data? {
        guard let img = snapshotActiveScreen(), let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
