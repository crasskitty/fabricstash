import Foundation

enum YardageRejection: Equatable {
    case amountMustBePositive
    case notANumber
    case wouldBeNegative(shortfallYards: Double)
}

enum YardageDeduction: Equatable {
    case applied(remainingYards: Double)
    case rejected(YardageRejection)
}

/// Remaining yardage is the number stored on the fabric. A cut subtracts from it
/// and is refused when the result would be negative.
enum YardageLedger {
    /// Absorbs binary dust such as 0.1 + 0.2 versus 0.3. It is not a sewing fudge factor.
    static let tolerance = 0.000_000_1

    static func deduct(remainingYards: Double, amountYards: Double) -> YardageDeduction {
        guard remainingYards.isFinite, amountYards.isFinite else {
            return .rejected(.notANumber)
        }
        guard amountYards > 0 else {
            return .rejected(.amountMustBePositive)
        }
        if amountYards > remainingYards + tolerance {
            let shortfall = amountYards - remainingYards
            return .rejected(.wouldBeNegative(shortfallYards: max(shortfall, 0)))
        }
        let next = remainingYards - amountYards
        let clamped = next <= tolerance ? 0 : next
        return .applied(remainingYards: clamped)
    }

    /// Putting a recorded cut back on the shelf.
    static func restore(remainingYards: Double, usedYards: Double) -> Double {
        guard remainingYards.isFinite, usedYards.isFinite else { return remainingYards }
        return remainingYards + max(0, usedYards)
    }
}
