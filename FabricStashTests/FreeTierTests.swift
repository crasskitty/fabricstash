import XCTest
@testable import FabricStash

final class FreeTierTests: XCTestCase {
    func testLimitIsTwentyFiveStoredFabrics() {
        XCTAssertEqual(FreeTier.fabricLimit, 25)
    }

    func testLockedShelfAllowsAddsUnderTheCap() {
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: 0, isUnlocked: false))
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: 24, isUnlocked: false))
    }

    func testLockedShelfRefusesTheTwentySixthFabric() {
        XCTAssertFalse(FreeTier.canAddFabric(currentCount: 25, isUnlocked: false))
        XCTAssertFalse(FreeTier.canAddFabric(currentCount: 26, isUnlocked: false))
    }

    func testUnlockRemovesTheCap() {
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: 25, isUnlocked: true))
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: 200, isUnlocked: true))
    }

    func testDeletingBackUnderTheCapFreesASlot() {
        let stored = 25
        XCTAssertFalse(FreeTier.canAddFabric(currentCount: stored, isUnlocked: false))
        let afterDelete = stored - 1
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: afterDelete, isUnlocked: false))
    }

    func testTheCheckDoesNotCareHowManyWereCreatedOverTime() {
        XCTAssertTrue(FreeTier.canAddFabric(currentCount: 3, isUnlocked: false))
        XCTAssertFalse(FreeTier.canAddFabric(currentCount: FreeTier.fabricLimit, isUnlocked: false))
    }
}
