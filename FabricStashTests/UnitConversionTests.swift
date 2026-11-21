import XCTest
@testable import FabricStash

final class UnitConversionTests: XCTestCase {
    func testOneYardIsTheInternationalMeter() {
        XCTAssertEqual(UnitConverter.meters(fromYards: 1), 0.9144, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromMeters: 0.9144), 1, accuracy: 0.000_000_1)
    }

    func testYardMeterRoundTrip() {
        let yards = 2.5
        let meters = UnitConverter.meters(fromYards: yards)
        XCTAssertEqual(meters, 2.286, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromMeters: meters), yards, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.meters(fromYards: 0), 0, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromMeters: 0), 0, accuracy: 0.000_000_1)
    }

    func testDisplayLengthUsesTheChosenUnit() {
        XCTAssertEqual(UnitConverter.displayLength(2, unit: .yards), 2, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.displayLength(2, unit: .meters), 1.8288, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromDisplay: 1.8288, unit: .meters), 2, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromDisplay: 2, unit: .yards), 2, accuracy: 0.000_000_1)
    }

    func testInchesAndCentimeters() {
        XCTAssertEqual(UnitConverter.centimeters(fromInches: 1), 2.54, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.inches(fromCentimeters: 2.54), 1, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.displayWidth(44, unit: .centimeters), 111.76, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.inches(fromDisplay: 111.76, unit: .centimeters), 44, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.inches(fromDisplay: 44, unit: .inches), 44, accuracy: 0.000_000_1)
    }

    func testGSMUsesTheGivenFactor() {
        XCTAssertEqual(UnitConverter.gsmPerOzPerSquareYard, 33.906, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.gsm(fromOzPerSqYard: 1), 33.906, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.ozPerSqYard(fromGSM: 33.906), 1, accuracy: 0.000_000_1)
    }

    func testWeightRoundTrip() {
        let ounces = 4.25
        let gsm = UnitConverter.gsm(fromOzPerSqYard: ounces)
        XCTAssertEqual(UnitConverter.ozPerSqYard(fromGSM: gsm), ounces, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.gsm(fromOzPerSqYard: 0), 0, accuracy: 0.000_000_1)
    }
}
