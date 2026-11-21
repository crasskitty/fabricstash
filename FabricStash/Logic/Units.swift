import Foundation

/// One choice sets both length and width. Imperial is yards and inches. Metric is meters and centimeters.
enum MeasurementSystem: String, CaseIterable, Identifiable, Hashable {
    case imperial
    case metric

    var id: String { rawValue }

    var title: String {
        switch self {
        case .imperial: "Imperial"
        case .metric: "Metric"
        }
    }

    var detail: String {
        switch self {
        case .imperial: "Inches and yards"
        case .metric: "Centimeters and meters"
        }
    }

    var lengthUnit: LengthUnit {
        switch self {
        case .imperial: .yards
        case .metric: .meters
        }
    }

    var widthUnit: WidthUnit {
        switch self {
        case .imperial: .inches
        case .metric: .centimeters
        }
    }
}

enum LengthUnit: String, CaseIterable, Identifiable {
    case yards
    case meters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yards: "Yards"
        case .meters: "Meters"
        }
    }

    var abbreviation: String {
        switch self {
        case .yards: "yd"
        case .meters: "m"
        }
    }
}

enum WidthUnit: String, CaseIterable, Identifiable {
    case inches
    case centimeters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inches: "Inches"
        case .centimeters: "Centimeters"
        }
    }

    var abbreviation: String {
        switch self {
        case .inches: "in"
        case .centimeters: "cm"
        }
    }
}

/// Canonical storage is yards and inches.
/// 1 yard = 0.9144 m. GSM = oz/yd² × 33.906.
enum UnitConverter {
    static let metersPerYard = 0.9144
    static let centimetersPerInch = 2.54
    static let inchesPerYard = 36.0
    static let gsmPerOzPerSquareYard = 33.906

    static func meters(fromYards yards: Double) -> Double {
        yards * metersPerYard
    }

    static func yards(fromMeters meters: Double) -> Double {
        meters / metersPerYard
    }

    static func centimeters(fromInches inches: Double) -> Double {
        inches * centimetersPerInch
    }

    static func inches(fromCentimeters centimeters: Double) -> Double {
        centimeters / centimetersPerInch
    }

    static func gsm(fromOzPerSqYard ounces: Double) -> Double {
        ounces * gsmPerOzPerSquareYard
    }

    static func ozPerSqYard(fromGSM gsm: Double) -> Double {
        gsm / gsmPerOzPerSquareYard
    }

    static func displayLength(_ yards: Double, unit: LengthUnit) -> Double {
        switch unit {
        case .yards: yards
        case .meters: meters(fromYards: yards)
        }
    }

    static func yards(fromDisplay value: Double, unit: LengthUnit) -> Double {
        switch unit {
        case .yards: value
        case .meters: yards(fromMeters: value)
        }
    }

    static func displayWidth(_ inches: Double, unit: WidthUnit) -> Double {
        switch unit {
        case .inches: inches
        case .centimeters: centimeters(fromInches: inches)
        }
    }

    static func inches(fromDisplay value: Double, unit: WidthUnit) -> Double {
        switch unit {
        case .inches: value
        case .centimeters: inches(fromCentimeters: value)
        }
    }
}

/// Converts only when a number is shown or typed. Stored yards and inches stay put when the setting changes.
enum MeasurementEdge {
    static func lengthText(yards: Double, system: MeasurementSystem) -> String {
        switch system {
        case .imperial:
            return FractionParsing.string(from: yards)
        case .metric:
            return NumberParsing.string(UnitConverter.meters(fromYards: yards), fractionDigits: 6)
        }
    }

    static func widthText(inches: Double, system: MeasurementSystem) -> String {
        switch system {
        case .imperial:
            return FractionParsing.string(from: inches)
        case .metric:
            return NumberParsing.string(UnitConverter.centimeters(fromInches: inches), fractionDigits: 6)
        }
    }

    static func yards(from text: String, system: MeasurementSystem) -> Double? {
        guard let value = entered(text, system: system) else { return nil }
        return UnitConverter.yards(fromDisplay: value, unit: system.lengthUnit)
    }

    static func inches(from text: String, system: MeasurementSystem) -> Double? {
        guard let value = entered(text, system: system) else { return nil }
        return UnitConverter.inches(fromDisplay: value, unit: system.widthUnit)
    }

    /// An untouched field keeps the stored number, so a unit change cannot rewrite it.
    static func resolvedYards(text: String, canonical: Double?, system: MeasurementSystem) -> Double? {
        if let canonical, text == lengthText(yards: canonical, system: system) {
            return canonical
        }
        return yards(from: text, system: system)
    }

    static func resolvedInches(text: String, canonical: Double?, system: MeasurementSystem) -> Double? {
        if let canonical, text == widthText(inches: canonical, system: system) {
            return canonical
        }
        return inches(from: text, system: system)
    }

    private static func entered(_ text: String, system: MeasurementSystem) -> Double? {
        switch system {
        case .imperial:
            return FractionParsing.value(from: text)
        case .metric:
            return NumberParsing.double(from: text)
        }
    }
}

/// Imperial entry such as 1/2, 3/8, and 44 1/2. Decimals still work. Metric entry does not use this.
enum FractionParsing {
    static func value(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if !trimmed.contains("/") {
            return NumberParsing.double(from: trimmed)
        }
        let spaced = trimmed.replacingOccurrences(of: "-", with: " ")
        let parts = spaced.split(whereSeparator: \.isWhitespace).map(String.init)
        if parts.count == 1 {
            return fraction(parts[0])
        }
        if parts.count == 2, let whole = Double(parts[0]), whole >= 0, let part = fraction(parts[1]) {
            return whole + part
        }
        return nil
    }

    /// Shows a sewing fraction through sixteenths when the number lands on one.
    static func string(from value: Double) -> String {
        guard value.isFinite else { return "" }
        let negative = value < 0
        let absolute = abs(value)
        let whole = floor(absolute + 0.000_000_000_1)
        let remainder = absolute - whole
        let sixteenths = (remainder * 16).rounded()
        let snapped = abs(remainder * 16 - sixteenths) < 0.000_001 && sixteenths >= 0 && sixteenths <= 16
        let body: String
        if snapped {
            if sixteenths == 0 || sixteenths == 16 {
                let shown = sixteenths == 16 ? whole + 1 : whole
                body = NumberParsing.string(shown, fractionDigits: 0)
            } else {
                let reduced = reduce(Int(sixteenths), 16)
                let fraction = "\(reduced.0)/\(reduced.1)"
                body = whole == 0 ? fraction : "\(Int(whole)) \(fraction)"
            }
        } else {
            body = NumberParsing.string(absolute, fractionDigits: 4)
        }
        return negative ? "-\(body)" : body
    }

    private static func fraction(_ token: String) -> Double? {
        let bits = token.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard bits.count == 2,
              let numerator = Double(bits[0]),
              let denominator = Double(bits[1]),
              denominator != 0,
              numerator >= 0,
              denominator > 0 else { return nil }
        return numerator / denominator
    }

    private static func reduce(_ numerator: Int, _ denominator: Int) -> (Int, Int) {
        var a = numerator
        var b = denominator
        while b != 0 {
            let remainder = a % b
            a = b
            b = remainder
        }
        let divisor = max(a, 1)
        return (numerator / divisor, denominator / divisor)
    }
}

enum NumberParsing {
    static func double(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let current = NumberFormatter()
        current.locale = .current
        current.numberStyle = .decimal
        if let number = current.number(from: trimmed) {
            return number.doubleValue
        }
        let posix = NumberFormatter()
        posix.locale = Locale(identifier: "en_US_POSIX")
        posix.numberStyle = .decimal
        return posix.number(from: trimmed)?.doubleValue
    }

    static func string(_ value: Double, fractionDigits: Int = 2) -> String {
        value.formatted(
            .number
                .locale(.current)
                .grouping(.never)
                .precision(.fractionLength(0...fractionDigits))
        )
    }

    static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let value = Decimal(string: trimmed, locale: .current) {
            return value
        }
        return Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
    }
}

extension Decimal {
    /// Locale-stable string for on-device storage. Not a currency format.
    var posixStorageString: String {
        formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...4))
        )
    }
}
