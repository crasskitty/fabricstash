import XCTest
@testable import FabricStash

final class YardageDeductionTests: XCTestCase {
    func testDeductsFromWhatIsLeft() {
        let result = YardageLedger.deduct(remainingYards: 2, amountYards: 0.5)
        XCTAssertEqual(result, .applied(remainingYards: 1.5))
    }

    func testExactCutLeavesZero() {
        let result = YardageLedger.deduct(remainingYards: 1.25, amountYards: 1.25)
        XCTAssertEqual(result, .applied(remainingYards: 0))
    }

    func testRefusesACutThatWouldGoNegative() {
        let result = YardageLedger.deduct(remainingYards: 0.4, amountYards: 0.5)
        guard case .rejected(.wouldBeNegative(let shortfall)) = result else {
            return XCTFail("Expected a refusal")
        }
        XCTAssertEqual(shortfall, 0.1, accuracy: 0.000_000_1)
    }

    func testNothingIsImpliedToChangeWhenRefused() {
        let remaining = 0.4
        let result = YardageLedger.deduct(remainingYards: remaining, amountYards: 1)
        guard case .rejected(.wouldBeNegative(let shortfall)) = result else {
            return XCTFail("Expected a refusal")
        }
        XCTAssertEqual(shortfall, 0.6, accuracy: 0.000_000_1)
        XCTAssertEqual(remaining, 0.4, accuracy: 0.000_000_1)
    }

    func testRejectsZeroAndNegativeAmounts() {
        XCTAssertEqual(YardageLedger.deduct(remainingYards: 2, amountYards: 0), .rejected(.amountMustBePositive))
        XCTAssertEqual(YardageLedger.deduct(remainingYards: 2, amountYards: -0.25), .rejected(.amountMustBePositive))
    }

    func testRejectsNonNumbers() {
        XCTAssertEqual(
            YardageLedger.deduct(remainingYards: .nan, amountYards: 1),
            .rejected(.notANumber)
        )
        XCTAssertEqual(
            YardageLedger.deduct(remainingYards: 1, amountYards: .infinity),
            .rejected(.notANumber)
        )
    }

    func testBinaryDustStillReachesZero() {
        let remaining = 0.3
        let amount = 0.1 + 0.2
        let result = YardageLedger.deduct(remainingYards: remaining, amountYards: amount)
        XCTAssertEqual(result, .applied(remainingYards: 0))
    }

    func testRestorePutsACutBack() {
        XCTAssertEqual(YardageLedger.restore(remainingYards: 1.5, usedYards: 0.5), 2, accuracy: 0.000_000_1)
        XCTAssertEqual(YardageLedger.restore(remainingYards: 1, usedYards: -2), 1, accuracy: 0.000_000_1)
    }
}
