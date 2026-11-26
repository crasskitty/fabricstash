import SwiftUI
import UIKit

/// Shows one cloth photo and samples the color under a tap. The ring sits on the sampled spot.
struct ColorSamplerView: View {
    var image: UIImage
    @Binding var point: CGPoint?
    var onSample: (RGB) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private static let voiceOverStops: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.33, y: 0.33),
        CGPoint(x: 0.67, y: 0.33),
        CGPoint(x: 0.33, y: 0.67),
        CGPoint(x: 0.67, y: 0.67),
        CGPoint(x: 0.5, y: 0.22),
        CGPoint(x: 0.5, y: 0.78),
        CGPoint(x: 0.22, y: 0.5),
        CGPoint(x: 0.78, y: 0.5)
    ]

    var body: some View {
        GeometryReader { geo in
            let fitted = fittedRect(imageSize: image.size, in: geo.size)
            ZStack {
                Studio.paper
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                if let point {
                    sampleMark(at: point, fitted: fitted, canvas: geo.size)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sample(at: value.location, fitted: fitted)
                    }
            )
        }
        .frame(height: sizeClass == .regular ? 360 : 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Studio.ink.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fabric photo")
        .accessibilityValue(point == nil ? "No spot sampled yet" : "Color sampled from the cloth")
        .accessibilityHint("Tap the cloth to sample its color. Swipe up or down to move the sample.")
        .accessibilityAdjustableAction { direction in
            let current = point ?? CGPoint(x: 0.5, y: 0.5)
            let stops = Self.voiceOverStops
            let nearest = stops.enumerated().min { lhs, rhs in
                distance(lhs.element, current) < distance(rhs.element, current)
            }?.offset ?? 0
            let nextIndex = direction == .increment
                ? (nearest + 1) % stops.count
                : (nearest - 1 + stops.count) % stops.count
            let next = stops[nextIndex]
            point = next
            if let rgb = PixelSampler.color(in: image, atNormalized: next) {
                onSample(rgb)
            }
        }
    }

    private func sample(at location: CGPoint, fitted: CGRect) {
        guard let normalized = normalizedPoint(location, fitted: fitted) else { return }
        point = normalized
        if let rgb = PixelSampler.color(in: image, atNormalized: normalized) {
            onSample(rgb)
        }
    }

    private func sampleMark(at point: CGPoint, fitted: CGRect, canvas: CGSize) -> some View {
        let spot = CGPoint(
            x: fitted.minX + point.x * fitted.width,
            y: fitted.minY + point.y * fitted.height
        )
        return ZStack {
            ClothLoupe(image: image, point: point)
                .position(loupeCenter(spot: spot, canvas: canvas))
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.45), lineWidth: 3)
                    .frame(width: 28, height: 28)
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1, height: 8)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8, height: 1)
            }
            .position(spot)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func loupeCenter(spot: CGPoint, canvas: CGSize) -> CGPoint {
        var y = spot.y - 48
        if y < 32 { y = spot.y + 48 }
        let x = min(max(spot.x, 32), canvas.width - 32)
        y = min(max(y, 32), canvas.height - 32)
        return CGPoint(x: x, y: y)
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    private func fittedRect(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
            return CGRect(origin: .zero, size: viewSize)
        }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (viewSize.width - width) / 2,
            y: (viewSize.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func normalizedPoint(_ location: CGPoint, fitted: CGRect) -> CGPoint? {
        guard fitted.width > 0, fitted.height > 0 else { return nil }
        let x = min(1, max(0, (location.x - fitted.minX) / fitted.width))
        let y = min(1, max(0, (location.y - fitted.minY) / fitted.height))
        let inside = fitted.insetBy(dx: -8, dy: -8).contains(location)
        guard inside else { return nil }
        return CGPoint(x: x, y: y)
    }
}

private struct ClothLoupe: View {
    var image: UIImage
    var point: CGPoint

    var body: some View {
        Canvas { context, size in
            let source = image.size
            guard source.width > 0, source.height > 0, size.width > 0 else { return }
            let crop = min(source.width, source.height) * 0.16
            let origin = CGPoint(
                x: point.x * source.width - crop / 2,
                y: point.y * source.height - crop / 2
            )
            var magnified = context
            magnified.clip(to: Path(ellipseIn: CGRect(origin: .zero, size: size)))
            magnified.scaleBy(x: size.width / crop, y: size.height / crop)
            magnified.translateBy(x: -origin.x, y: -origin.y)
            magnified.draw(Image(uiImage: image), in: CGRect(origin: .zero, size: source))
        }
        .frame(width: 56, height: 56)
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1).padding(1))
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}
