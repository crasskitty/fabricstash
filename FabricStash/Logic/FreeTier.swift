import Foundation

/// The free shelf is a cap on how many fabrics are stored right now.
/// Deleting a fabric frees a slot. Editing an existing fabric is always allowed.
enum FreeTier {
    static let fabricLimit = 25

    static func canAddFabric(currentCount: Int, isUnlocked: Bool) -> Bool {
        if isUnlocked { return true }
        return currentCount < fabricLimit
    }
}
