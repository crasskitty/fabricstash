import Foundation
import Observation

@MainActor
@Observable
final class UnitSettings {
    private enum Key {
        static let system = "fabricstash.unit.system"
    }

    var system: MeasurementSystem {
        didSet { UserDefaults.standard.set(system.rawValue, forKey: Key.system) }
    }

    var lengthUnit: LengthUnit { system.lengthUnit }
    var widthUnit: WidthUnit { system.widthUnit }

    init() {
        let stored = UserDefaults.standard.string(forKey: Key.system)
        system = stored.flatMap(MeasurementSystem.init(rawValue:)) ?? .imperial
    }

    func formatLength(yards: Double) -> String {
        "\(MeasurementEdge.lengthText(yards: yards, system: system)) \(lengthUnit.abbreviation)"
    }

    func formatWidth(inches: Double) -> String {
        "\(MeasurementEdge.widthText(inches: inches, system: system)) \(widthUnit.abbreviation)"
    }

    func yards(fromDisplay text: String) -> Double? {
        MeasurementEdge.yards(from: text, system: system)
    }

    func inches(fromDisplay text: String) -> Double? {
        MeasurementEdge.inches(from: text, system: system)
    }

    func resolvedYards(text: String, canonical: Double?) -> Double? {
        MeasurementEdge.resolvedYards(text: text, canonical: canonical, system: system)
    }

    func resolvedInches(text: String, canonical: Double?) -> Double? {
        MeasurementEdge.resolvedInches(text: text, canonical: canonical, system: system)
    }

    func lengthField(yards: Double) -> String {
        MeasurementEdge.lengthText(yards: yards, system: system)
    }

    func widthField(inches: Double) -> String {
        MeasurementEdge.widthText(inches: inches, system: system)
    }
}
