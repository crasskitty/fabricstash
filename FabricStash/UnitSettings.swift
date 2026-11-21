import Foundation
import Observation

@MainActor
@Observable
final class UnitSettings {
    private enum Key {
        static let length = "fabricstash.unit.length"
        static let width = "fabricstash.unit.width"
    }

    var lengthUnit: LengthUnit {
        didSet { UserDefaults.standard.set(lengthUnit.rawValue, forKey: Key.length) }
    }

    var widthUnit: WidthUnit {
        didSet { UserDefaults.standard.set(widthUnit.rawValue, forKey: Key.width) }
    }

    init() {
        let storedLength = UserDefaults.standard.string(forKey: Key.length)
        let storedWidth = UserDefaults.standard.string(forKey: Key.width)
        lengthUnit = storedLength.flatMap(LengthUnit.init(rawValue:)) ?? .yards
        widthUnit = storedWidth.flatMap(WidthUnit.init(rawValue:)) ?? .inches
    }

    func formatLength(yards: Double) -> String {
        let shown = UnitConverter.displayLength(yards, unit: lengthUnit)
        return "\(NumberParsing.string(shown)) \(lengthUnit.abbreviation)"
    }

    func formatWidth(inches: Double) -> String {
        let shown = UnitConverter.displayWidth(inches, unit: widthUnit)
        return "\(NumberParsing.string(shown)) \(widthUnit.abbreviation)"
    }

    func yards(fromDisplay text: String) -> Double? {
        guard let value = NumberParsing.double(from: text) else { return nil }
        return UnitConverter.yards(fromDisplay: value, unit: lengthUnit)
    }

    func inches(fromDisplay text: String) -> Double? {
        guard let value = NumberParsing.double(from: text) else { return nil }
        return UnitConverter.inches(fromDisplay: value, unit: widthUnit)
    }

    func lengthField(yards: Double) -> String {
        NumberParsing.string(UnitConverter.displayLength(yards, unit: lengthUnit))
    }

    func widthField(inches: Double) -> String {
        NumberParsing.string(UnitConverter.displayWidth(inches, unit: widthUnit))
    }
}
