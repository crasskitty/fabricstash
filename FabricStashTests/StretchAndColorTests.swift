import XCTest
@testable import FabricStash

final class StretchAssessmentTests: XCTestCase {
    func testPercentFromATenCentimeterMark() throws {
        let stretched = try XCTUnwrap(StretchAssessment.percent(stretchedCentimeters: 13))
        let relaxed = try XCTUnwrap(StretchAssessment.percent(stretchedCentimeters: 10))
        XCTAssertEqual(stretched, 30, accuracy: 0.000_000_1)
        XCTAssertEqual(relaxed, 0, accuracy: 0.000_000_1)
        XCTAssertNil(StretchAssessment.percent(stretchedCentimeters: 9))
    }

    func testKindFromBothDirections() {
        XCTAssertEqual(StretchAssessment.kind(crosswisePercent: 30, lengthwisePercent: 30), .fourWay)
        XCTAssertEqual(StretchAssessment.kind(crosswisePercent: 30, lengthwisePercent: 5), .twoWay)
        XCTAssertEqual(StretchAssessment.kind(crosswisePercent: 5, lengthwisePercent: 40), .twoWay)
        XCTAssertEqual(StretchAssessment.kind(crosswisePercent: 14.9, lengthwisePercent: 14.9), .none)
        XCTAssertEqual(StretchAssessment.kind(crosswisePercent: 15, lengthwisePercent: 15), .fourWay)
    }

    func testPoorRecoveryWins() {
        XCTAssertEqual(StretchAssessment.combinedRecovery(.good, .poor), .poor)
        XCTAssertEqual(StretchAssessment.combinedRecovery(.good, .good), .good)
    }
}

final class ColorMathTests: XCTestCase {
    func testNearWhiteBackgroundIsLeftOut() throws {
        let white = RGB(hex: "#FFFFFF")!
        let madder = RGB(hex: "#9C4A32")!
        let pixels = Array(repeating: white, count: 20) + Array(repeating: madder, count: 10)
        let result = DominantColor.representative(pixels)
        XCTAssertEqual(result?.r ?? -1, madder.r, accuracy: 0.02)
        XCTAssertEqual(result?.g ?? -1, madder.g, accuracy: 0.02)
        XCTAssertEqual(result?.b ?? -1, madder.b, accuracy: 0.02)
        let suggestion = try XCTUnwrap(ColorNaming.suggestion(from: pixels))
        XCTAssertEqual(suggestion.name, "Madder")
        XCTAssertEqual(suggestion.ignoredPaleBackground, true)
    }

    func testMostlyWhiteFrameStaysALightColor() {
        let white = RGB(hex: "#F7F5F2")!
        var pixels = Array(repeating: white, count: 100)
        pixels.append(RGB(hex: "#9C4A32")!)
        let result = DominantColor.representative(pixels)
        XCTAssertGreaterThan(result?.r ?? 0, 0.9)
        XCTAssertTrue(DominantColor.isNearWhite(white))
        XCTAssertFalse(DominantColor.isNearWhite(RGB(hex: "#9C4A32")!))
    }

    func testHexRoundTrip() throws {
        let rgb = RGB(hex: "#9C4A32")
        XCTAssertEqual(try XCTUnwrap(rgb).hex, "#9C4A32")
        XCTAssertEqual(try XCTUnwrap(RGB(hex: "9C4")).hex, "#99CC44")
        XCTAssertNil(RGB(hex: "nope"))
    }
}

final class CSVExportTests: XCTestCase {
    func testQuotesCommasAndDoublesQuotes() {
        XCTAssertEqual(CSVExport.field("plain"), "plain")
        XCTAssertEqual(CSVExport.field("a, b"), "\"a, b\"")
        XCTAssertEqual(CSVExport.field("say \"hi\""), "\"say \"\"hi\"\"\"")
    }

    func testRenderIncludesTheHeaderAndARow() {
        let row = FabricExportRow(
            name: "Sample, Gingham",
            fiberContent: "cotton",
            structure: "Woven",
            type: "Quilting cotton",
            yardageOnHandYards: "2.5",
            widthInches: "44",
            isScrap: "no",
            scrapWidthInches: "",
            scrapLengthInches: "",
            weightGSM: "",
            weightOzPerSqYd: "",
            colorName: "Red",
            colorHex: "#B4332A",
            printPattern: "large red gingham",
            stretchCrosswisePercent: "",
            stretchLengthwisePercent: "",
            stretch: "No stretch",
            recovery: "Not tested",
            source: "Sample Dry Goods",
            pricePaid: "12.5",
            currencyCode: "USD",
            prewashed: "yes",
            careNotes: "line one\nline two",
            tags: "sample; cotton",
            storageLocation: "Sample shelf",
            storageKind: "Shelf",
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z",
            recordedUseYards: "0.5"
        )
        let csv = CSVExport.render(rows: [row])
        XCTAssertTrue(csv.hasPrefix("name,fiber_content,structure,"))
        XCTAssertTrue(csv.contains("\"Sample, Gingham\""))
        XCTAssertTrue(csv.contains("\"line one\nline two\""))
        XCTAssertEqual(CSVExport.headers.count, row.columns.count)
    }
}
