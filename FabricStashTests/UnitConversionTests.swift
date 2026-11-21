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

    func testOneSystemSetsBothUnits() {
        XCTAssertEqual(MeasurementSystem.imperial.lengthUnit, .yards)
        XCTAssertEqual(MeasurementSystem.imperial.widthUnit, .inches)
        XCTAssertEqual(MeasurementSystem.metric.lengthUnit, .meters)
        XCTAssertEqual(MeasurementSystem.metric.widthUnit, .centimeters)
    }

    func testFractionalInchEntry() {
        XCTAssertEqual(FractionParsing.value(from: "1/2") ?? -1, 0.5, accuracy: 0.000_000_1)
        XCTAssertEqual(FractionParsing.value(from: "3/8") ?? -1, 0.375, accuracy: 0.000_000_1)
        XCTAssertEqual(FractionParsing.value(from: "44 1/2") ?? -1, 44.5, accuracy: 0.000_000_1)
        XCTAssertEqual(FractionParsing.value(from: "44-1/2") ?? -1, 44.5, accuracy: 0.000_000_1)
        XCTAssertEqual(FractionParsing.value(from: "44.5") ?? -1, 44.5, accuracy: 0.000_000_1)
        XCTAssertEqual(FractionParsing.string(from: 44.5), "44 1/2")
        XCTAssertEqual(FractionParsing.string(from: 0.375), "3/8")
        XCTAssertEqual(FractionParsing.string(from: 0.5), "1/2")
    }

    func testTogglingUnitsDoesNotDriftCanonicalValues() {
        let inches = 44.5
        let yards = 2.5
        let centimeters = UnitConverter.displayWidth(inches, unit: .centimeters)
        let meters = UnitConverter.displayLength(yards, unit: .meters)
        XCTAssertEqual(UnitConverter.inches(fromDisplay: centimeters, unit: .centimeters), inches, accuracy: 0.000_000_1)
        XCTAssertEqual(UnitConverter.yards(fromDisplay: meters, unit: .meters), yards, accuracy: 0.000_000_1)

        let imperialText = MeasurementEdge.widthText(inches: inches, system: .imperial)
        XCTAssertEqual(MeasurementEdge.resolvedInches(text: imperialText, canonical: inches, system: .imperial) ?? -1, inches, accuracy: 0.000_000_1)
        let metricText = MeasurementEdge.widthText(inches: inches, system: .metric)
        XCTAssertEqual(MeasurementEdge.resolvedInches(text: metricText, canonical: inches, system: .metric) ?? -1, inches, accuracy: 0.000_000_1)

        let shownYards = MeasurementEdge.lengthText(yards: yards, system: .metric)
        let parsedYards = MeasurementEdge.yards(from: shownYards, system: .metric) ?? -1
        let backToImperial = MeasurementEdge.lengthText(yards: parsedYards, system: .imperial)
        XCTAssertEqual(MeasurementEdge.yards(from: backToImperial, system: .imperial) ?? -1, yards, accuracy: 0.000_000_1)
        XCTAssertEqual(MeasurementEdge.resolvedYards(text: shownYards, canonical: yards, system: .metric) ?? -1, yards, accuracy: 0.000_000_1)
    }
}
