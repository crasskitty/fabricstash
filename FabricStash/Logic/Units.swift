import Foundation

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
