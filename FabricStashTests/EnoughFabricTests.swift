import XCTest
@testable import FabricStash

final class EnoughFabricTests: XCTestCase {
    func testBoltCoversWhenLengthAndWidthAreEnough() throws {
        let need = PieceNeed(yards: 1.5, widthInches: 44)
        let piece = bolt("Linen", yards: 2, width: 54)
        let match = try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: piece))
        XCTAssertEqual(match.kind, .covers)
    }

    func testExactLengthAndWidthStillCover() throws {
        let need = PieceNeed(yards: 2, widthInches: 45)
        let match = try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: bolt("Exact", yards: 2, width: 45)))
        XCTAssertEqual(match.kind, .covers)
    }

    func testShortYardageIsACloseMatchWithTheShortfall() throws {
        let need = PieceNeed(yards: 3, widthInches: 44)
        let match = try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: bolt("Short bolt", yards: 2.25, width: 45)))
        XCTAssertEqual(match.kind, .short(.yardage(yards: 0.75)))
    }

    func testShortWidthIsACloseMatchWhenLengthCovers() throws {
        let need = PieceNeed(yards: 1, widthInches: 60)
        let match = try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: bolt("Narrow", yards: 2, width: 45)))
        XCTAssertEqual(match.kind, .short(.width(inches: 15)))
    }

    func testBothDimensionsShortIsNotListed() {
        let need = PieceNeed(yards: 3, widthInches: 60)
        let match = EnoughFabricMatcher.match(need: need, piece: bolt("Neither", yards: 1, width: 44))
        XCTAssertNil(match)
    }

    func testUsedUpBoltIsNotACloseMatch() {
        let need = PieceNeed(yards: 1, widthInches: 44)
        let match = EnoughFabricMatcher.match(need: need, piece: bolt("Empty", yards: 0, width: 54))
        XCTAssertNil(match)
    }

    func testInvalidNeedMatchesNothing() {
        let pieces = [bolt("Any", yards: 5, width: 60)]
        let result = EnoughFabricMatcher.classify(need: PieceNeed(yards: 0, widthInches: 44), pieces: pieces)
        XCTAssertTrue(result.covers.isEmpty)
        XCTAssertTrue(result.close.isEmpty)
    }

    func testClassifySortsCoversByNameAndKeepsShortSeparate() throws {
        let need = PieceNeed(yards: 2, widthInches: 45)
        let pieces = [
            bolt("Zebra", yards: 1, width: 50),
            bolt("Alpaca", yards: 3, width: 60),
            bolt("Moire", yards: 4, width: 45)
        ]
        let result = EnoughFabricMatcher.classify(need: need, pieces: pieces)
        XCTAssertEqual(result.covers.map(\.piece.name), ["Alpaca", "Moire"])
        XCTAssertEqual(result.close.map(\.piece.name), ["Zebra"])
        XCTAssertEqual(try XCTUnwrap(result.close.first).kind, .short(.yardage(yards: 1)))
    }

    func testScrapCoversInEitherOrientation() throws {
        let need = PieceNeed(yards: 1, widthInches: 20)
        let turned = scrap("Turned", width: 40, length: 20)
        let straight = scrap("Straight", width: 20, length: 40)
        XCTAssertEqual(try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: turned)).kind, .covers)
        XCTAssertEqual(try XCTUnwrap(EnoughFabricMatcher.match(need: need, piece: straight)).kind, .covers)
    }

    func testScrapPicksTheOrientationWithTheSmallerShortfall() throws {
        let need = PieceNeed(yards: 1, widthInches: 20)
        let piece = scrap("Almost", width: 30, length: 22)
        let match = EnoughFabricMatcher.match(need: need, piece: piece)
        XCTAssertEqual(try XCTUnwrap(match).kind, .short(.scrapEdge(inches: 6)))
    }

    func testScrapThatCannotSpanEitherSideIsOmitted() {
        let need = PieceNeed(yards: 1, widthInches: 20)
        XCTAssertNil(EnoughFabricMatcher.match(need: need, piece: scrap("Tiny", width: 10, length: 10)))
    }

    private func bolt(_ name: String, yards: Double, width: Double) -> ShelfPiece {
        ShelfPiece(
            id: UUID(),
            name: name,
            remainingYards: yards,
            widthInches: width,
            isScrap: false,
            scrapWidthInches: 0,
            scrapLengthInches: 0
        )
    }

    private func scrap(_ name: String, width: Double, length: Double) -> ShelfPiece {
        ShelfPiece(
            id: UUID(),
            name: name,
            remainingYards: 0,
            widthInches: width,
            isScrap: true,
            scrapWidthInches: width,
            scrapLengthInches: length
        )
    }
}
