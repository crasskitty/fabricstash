import CoreTransferable
import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum PhotoEncoding {
    static func jpegData(from image: UIImage, maxEdge: CGFloat = 1600, quality: CGFloat = 0.82) -> Data? {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > 0 else { return nil }
        let ratio = longest > maxEdge ? maxEdge / longest : 1
        let target = CGSize(width: max(1, floor(pixelWidth * ratio)), height: max(1, floor(pixelHeight * ratio)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: quality)
    }

    static func solidJPEG(hex: String, size: CGFloat = 640) -> Data {
        let rgb = RGB(hex: hex) ?? RGB(r: 0.129, g: 0.369, b: 0.439)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let image = renderer.image { context in
            UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            UIColor(white: 0, alpha: 0.08).setFill()
            context.fill(CGRect(x: 0, y: size * 0.78, width: size, height: size * 0.08))
        }
        return image.jpegData(compressionQuality: 0.86) ?? Data()
    }

    static func thumbnail(data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    func image(id: UUID, data: Data, maxPixel: CGFloat) -> UIImage? {
        let key = "\(id.uuidString)-\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = PhotoEncoding.thumbnail(data: data, maxPixel: maxPixel) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

enum PixelSampler {
    static func pixels(from image: UIImage, edge: Int = 36) -> [RGB] {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: edge, height: edge), format: format)
        let small = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(edge), height: CGFloat(edge)))
        }
        guard let cgImage = small.cgImage else { return [] }
        let width = cgImage.width
        let height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        var pixels: [RGB] = []
        pixels.reserveCapacity(width * height)
        var index = 0
        while index + 3 < bytes.count {
            let alpha = Double(bytes[index + 3]) / 255
            if alpha >= 0.5 {
                pixels.append(RGB(
                    r: Double(bytes[index]) / 255,
                    g: Double(bytes[index + 1]) / 255,
                    b: Double(bytes[index + 2]) / 255
                ))
            }
            index += 4
        }
        return pixels
    }
}

enum PhotoColor {
    static func suggestion(for data: Data) -> ColorSuggestion? {
        guard let image = UIImage(data: data) else { return nil }
        return ColorNaming.suggestion(from: PixelSampler.pixels(from: image))
    }
}

extension PixelSampler {
    /// Average of a small neighborhood around a normalized point. The origin is the top left.
    static func color(in image: UIImage, atNormalized point: CGPoint, radius: Int = 2) -> RGB? {
        let clamped = CGPoint(x: min(1, max(0, point.x)), y: min(1, max(0, point.y)))
        guard let bitmap = uprightBitmap(of: image, maxEdge: 640) else { return nil }
        let x = Int((clamped.x * CGFloat(bitmap.width - 1)).rounded())
        let y = Int((clamped.y * CGFloat(bitmap.height - 1)).rounded())
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        var count = 0.0
        for dy in -radius...radius {
            for dx in -radius...radius {
                let px = min(bitmap.width - 1, max(0, x + dx))
                let py = min(bitmap.height - 1, max(0, y + dy))
                let index = (py * bitmap.width + px) * 4
                let alpha = Double(bitmap.bytes[index + 3]) / 255
                guard alpha >= 0.5 else { continue }
                red += Double(bitmap.bytes[index]) / 255
                green += Double(bitmap.bytes[index + 1]) / 255
                blue += Double(bitmap.bytes[index + 2]) / 255
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return RGB(r: red / count, g: green / count, b: blue / count)
    }

    private struct UprightBitmap {
        var bytes: [UInt8]
        var width: Int
        var height: Int
    }

    /// Draws the image in display orientation, with the first byte row at the top.
    private static func uprightBitmap(of image: UIImage, maxEdge: CGFloat) -> UprightBitmap? {
        let pixelWidth = max(1, image.size.width * image.scale)
        let pixelHeight = max(1, image.size.height * image.scale)
        let longest = max(pixelWidth, pixelHeight)
        let ratio = longest > maxEdge ? maxEdge / longest : 1
        let width = max(1, Int((pixelWidth * ratio).rounded(.down)))
        let height = max(1, Int((pixelHeight * ratio).rounded(.down)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        guard let cgImage = rendered.cgImage else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return UprightBitmap(bytes: bytes, width: width, height: height)
    }
}

struct ImportedPhoto: Transferable {
    var data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            ImportedPhoto(data: data)
        }
    }
}

struct CSVFile: Transferable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(AppIdentity.csvFilename)
            try Data(file.text.utf8).write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        context.coordinator.onCapture = onCapture
        context.coordinator.dismiss = dismiss
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        context.coordinator.onCapture = onCapture
        context.coordinator.dismiss = dismiss
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onCapture: ((Data) -> Void)?
        var dismiss: DismissAction?

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.originalImage] as? UIImage)
            if let image, let data = PhotoEncoding.jpegData(from: image) {
                onCapture?(data)
            }
            dismiss?()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss?()
        }
    }
}
