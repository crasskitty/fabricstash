import Foundation

struct RGB: Equatable {
    var r: Double
    var g: Double
    var b: Double

    var hex: String {
        func byte(_ channel: Double) -> Int {
            Int((min(1, max(0, channel)) * 255).rounded())
        }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        r = Double((value >> 16) & 0xFF) / 255
        g = Double((value >> 8) & 0xFF) / 255
        b = Double(value & 0xFF) / 255
    }

    var hsl: (h: Double, s: Double, l: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let lightness = (maxC + minC) / 2
        let delta = maxC - minC
        guard delta > 0.000_01 else { return (0, 0, lightness) }
        let saturation = delta / (1 - abs(2 * lightness - 1))
        let hue: Double
        if maxC == r {
            hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
        } else if maxC == g {
            hue = 60 * (((b - r) / delta) + 2)
        } else {
            hue = 60 * (((r - g) / delta) + 4)
        }
        let wrapped = hue < 0 ? hue + 360 : hue
        return (wrapped, saturation, lightness)
    }
}

struct ColorSuggestion: Equatable {
    var name: String
    var hex: String
    var ignoredPaleBackground: Bool
}

enum ColorFamily: String, CaseIterable, Identifiable, Hashable {
    case reds
    case oranges
    case yellows
    case greens
    case blues
    case purples
    case pinks
    case browns
    case neutrals
    case black
    case white

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reds: "Reds"
        case .oranges: "Oranges"
        case .yellows: "Yellows"
        case .greens: "Greens"
        case .blues: "Blues"
        case .purples: "Purples"
        case .pinks: "Pinks"
        case .browns: "Browns"
        case .neutrals: "Neutrals"
        case .black: "Black"
        case .white: "White"
        }
    }
}

enum DominantColor {
    /// Pale table or paper behind the cloth. High luminance, almost no chroma.
    static func isNearWhite(
        _ pixel: RGB,
        luminanceFloor: Double = 0.90,
        saturationCeiling: Double = 0.16
    ) -> Bool {
        let maxC = max(pixel.r, pixel.g, pixel.b)
        let minC = min(pixel.r, pixel.g, pixel.b)
        let luminance = 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
        let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC
        return luminance >= luminanceFloor && saturation <= saturationCeiling
    }

    /// Average of the pixels that are not a near-white background.
    /// If almost the whole frame is pale, the cloth itself is light, so the average of every pixel is used.
    static func representative(_ pixels: [RGB]) -> RGB? {
        guard !pixels.isEmpty else { return nil }
        let kept = pixels.filter { !isNearWhite($0) }
        let minimum = max(8, Int((Double(pixels.count) * 0.05).rounded(.up)))
        let basis = kept.count >= minimum ? kept : pixels
        return average(basis)
    }

    static func average(_ pixels: [RGB]) -> RGB? {
        guard !pixels.isEmpty else { return nil }
        let count = Double(pixels.count)
        let r = pixels.reduce(0) { $0 + $1.r } / count
        let g = pixels.reduce(0) { $0 + $1.g } / count
        let b = pixels.reduce(0) { $0 + $1.b } / count
        return RGB(r: r, g: g, b: b)
    }
}

enum ColorNaming {
    static let palette: [(name: String, hex: String)] = [
        ("White", "F7F5F2"),
        ("Ivory", "F3EDE2"),
        ("Cream", "F0E2C6"),
        ("Beige", "D9C7A6"),
        ("Tan", "C4A574"),
        ("Camel", "A67C52"),
        ("Brown", "6B4423"),
        ("Chocolate", "4A2E1F"),
        ("Black", "1A1614"),
        ("Charcoal", "3A3532"),
        ("Gray", "8A847C"),
        ("Silver", "C5C1B9"),
        ("Navy", "1E2A4A"),
        ("Blue", "2F5D9F"),
        ("Light blue", "A9C6E8"),
        ("Teal", "2F6F6A"),
        ("Aqua", "7EC8C3"),
        ("Green", "2E6B45"),
        ("Sage", "8AA58B"),
        ("Olive", "6B7032"),
        ("Lime", "C5D46A"),
        ("Yellow", "E6C84A"),
        ("Gold", "C6A15B"),
        ("Orange", "E07A2F"),
        ("Rust", "B85A2A"),
        ("Coral", "E38B78"),
        ("Red", "B4332A"),
        ("Madder", "9C4A32"),
        ("Burgundy", "6E2430"),
        ("Pink", "E7A3B2"),
        ("Blush", "F0D0CB"),
        ("Purple", "5E3A6B"),
        ("Lavender", "C7B4D6"),
        ("Maroon", "6A2E2A")
    ]

    static func nearestName(to rgb: RGB) -> String {
        var bestName = "Color"
        var bestDistance = Double.greatestFiniteMagnitude
        for entry in palette {
            guard let swatch = RGB(hex: entry.hex) else { continue }
            let distance = pow(swatch.r - rgb.r, 2) + pow(swatch.g - rgb.g, 2) + pow(swatch.b - rgb.b, 2)
            if distance < bestDistance {
                bestDistance = distance
                bestName = entry.name
            }
        }
        return bestName
    }

    static func family(of rgb: RGB) -> ColorFamily {
        let (hue, saturation, lightness) = rgb.hsl
        if lightness <= 0.10 { return .black }
        if lightness >= 0.92 && saturation <= 0.14 { return .white }
        if saturation <= 0.12 {
            return lightness >= 0.82 ? .white : .neutrals
        }
        if (15...50).contains(hue), lightness < 0.55, saturation < 0.80 {
            return .browns
        }
        switch hue {
        case 0..<15, 345...360:
            return lightness > 0.72 ? .pinks : .reds
        case 15..<45:
            return .oranges
        case 45..<75:
            return .yellows
        case 75..<170:
            return .greens
        case 170..<255:
            return .blues
        case 255..<295:
            return .purples
        default:
            return .pinks
        }
    }

    static func family(hex: String) -> ColorFamily? {
        guard let rgb = RGB(hex: hex) else { return nil }
        return family(of: rgb)
    }

    static func suggestion(from pixels: [RGB]) -> ColorSuggestion? {
        guard let rgb = DominantColor.representative(pixels) else { return nil }
        let paleCount = pixels.filter { DominantColor.isNearWhite($0) }.count
        let minimum = max(8, Int((Double(pixels.count) * 0.05).rounded(.up)))
        let kept = pixels.count - paleCount
        return ColorSuggestion(
            name: nearestName(to: rgb),
            hex: rgb.hex,
            ignoredPaleBackground: paleCount > 0 && kept >= minimum
        )
    }
}
