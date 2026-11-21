import Foundation

enum StretchKind: String, CaseIterable, Identifiable, Hashable {
    case none
    case twoWay
    case fourWay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "No stretch"
        case .twoWay: "2-way"
        case .fourWay: "4-way"
        }
    }
}

enum Recovery: String, CaseIterable, Identifiable, Hashable {
    case untested
    case good
    case poor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .untested: "Not tested"
        case .good: "Good recovery"
        case .poor: "Poor recovery"
        }
    }
}

struct StretchTestResult: Equatable {
    var crosswisePercent: Double
    var lengthwisePercent: Double
    var crosswiseRecovery: Recovery
    var lengthwiseRecovery: Recovery
    var kind: StretchKind
    var recovery: Recovery
}

/// A tape-measure test. The phone does not measure stretch.
enum StretchAssessment {
    static let markedCentimeters = 10.0
    /// Below this, the cloth is treated as not really stretching in that direction.
    static let meaningfulPercent = 15.0

    static func percent(stretchedCentimeters: Double, markedCentimeters: Double = markedCentimeters) -> Double? {
        guard stretchedCentimeters.isFinite, markedCentimeters > 0, markedCentimeters.isFinite else {
            return nil
        }
        guard stretchedCentimeters + 0.000_1 >= markedCentimeters else { return nil }
        return (stretchedCentimeters - markedCentimeters) / markedCentimeters * 100
    }

    static func kind(crosswisePercent: Double, lengthwisePercent: Double) -> StretchKind {
        let crosswise = crosswisePercent >= meaningfulPercent
        let lengthwise = lengthwisePercent >= meaningfulPercent
        switch (crosswise, lengthwise) {
        case (true, true):
            return .fourWay
        case (false, false):
            return .none
        default:
            return .twoWay
        }
    }

    static func combinedRecovery(_ crosswise: Recovery, _ lengthwise: Recovery) -> Recovery {
        if crosswise == .poor || lengthwise == .poor { return .poor }
        if crosswise == .good || lengthwise == .good { return .good }
        return .untested
    }

    static func result(
        crosswisePercent: Double,
        lengthwisePercent: Double,
        crosswiseRecovery: Recovery,
        lengthwiseRecovery: Recovery
    ) -> StretchTestResult {
        StretchTestResult(
            crosswisePercent: crosswisePercent,
            lengthwisePercent: lengthwisePercent,
            crosswiseRecovery: crosswiseRecovery,
            lengthwiseRecovery: lengthwiseRecovery,
            kind: kind(crosswisePercent: crosswisePercent, lengthwisePercent: lengthwisePercent),
            recovery: combinedRecovery(crosswiseRecovery, lengthwiseRecovery)
        )
    }

    static func explanation(for kind: StretchKind, crosswise: Double, lengthwise: Double) -> String {
        switch kind {
        case .fourWay:
            "It stretches both ways, so this is 4-way. Crosswise is \(NumberParsing.string(crosswise))%, lengthwise is \(NumberParsing.string(lengthwise))%."
        case .twoWay:
            if crosswise >= lengthwise {
                "It stretches crosswise and barely along the length, so this is 2-way."
            } else {
                "It stretches along the length and barely crosswise, so this is 2-way."
            }
        case .none:
            "It barely moves in either direction, so record it as no stretch."
        }
    }
}
