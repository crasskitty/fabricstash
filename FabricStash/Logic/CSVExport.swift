import Foundation

struct FabricExportRow: Equatable {
    var name: String
    var fiberContent: String
    var structure: String
    var type: String
    var yardageOnHandYards: String
    var widthInches: String
    var isScrap: String
    var scrapWidthInches: String
    var scrapLengthInches: String
    var weightGSM: String
    var weightOzPerSqYd: String
    var colorName: String
    var colorHex: String
    var printPattern: String
    var stretchCrosswisePercent: String
    var stretchLengthwisePercent: String
    var stretch: String
    var recovery: String
    var source: String
    var pricePaid: String
    var currencyCode: String
    var prewashed: String
    var careNotes: String
    var tags: String
    var storageLocation: String
    var storageKind: String
    var createdAt: String
    var updatedAt: String
    var recordedUseYards: String

    var columns: [String] {
        [
            name, fiberContent, structure, type, yardageOnHandYards, widthInches,
            isScrap, scrapWidthInches, scrapLengthInches, weightGSM, weightOzPerSqYd,
            colorName, colorHex, printPattern, stretchCrosswisePercent, stretchLengthwisePercent,
            stretch, recovery, source, pricePaid, currencyCode, prewashed, careNotes, tags,
            storageLocation, storageKind, createdAt, updatedAt, recordedUseYards
        ]
    }
}

enum CSVExport {
    static let headers = [
        "name", "fiber_content", "structure", "type", "yardage_on_hand_yards", "width_inches",
        "is_scrap", "scrap_width_inches", "scrap_length_inches", "weight_gsm", "weight_oz_per_sq_yd",
        "color_name", "color_hex", "print_pattern", "stretch_crosswise_percent", "stretch_lengthwise_percent",
        "stretch", "recovery", "source", "price_paid", "currency_code", "prewashed", "care_notes", "tags",
        "storage_location", "storage_kind", "created_at", "updated_at", "recorded_use_yards"
    ]

    static func render(rows: [FabricExportRow]) -> String {
        var lines = [line(headers)]
        lines.append(contentsOf: rows.map { line($0.columns) })
        return lines.joined(separator: "\n") + "\n"
    }

    static func field(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    private static func line(_ columns: [String]) -> String {
        columns.map(field).joined(separator: ",")
    }

    static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func number(_ value: Double) -> String {
        value.formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...4))
        )
    }
}
