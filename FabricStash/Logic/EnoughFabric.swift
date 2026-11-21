import Foundation

struct PieceNeed: Equatable {
    var yards: Double
    var widthInches: Double

    var isPositive: Bool {
        yards > 0 && widthInches > 0 && yards.isFinite && widthInches.isFinite
    }

    var lengthInches: Double { yards * UnitConverter.inchesPerYard }
}

struct ShelfPiece: Equatable, Identifiable {
    var id: UUID
    var name: String
    var remainingYards: Double
    var widthInches: Double
    var isScrap: Bool
    var scrapWidthInches: Double
    var scrapLengthInches: Double
}

enum FabricShortfall: Equatable {
    case yardage(yards: Double)
    case width(inches: Double)
    case scrapEdge(inches: Double)
}

struct FabricMatch: Equatable, Identifiable {
    enum Kind: Equatable {
        case covers
        case short(FabricShortfall)
    }

    var piece: ShelfPiece
    var kind: Kind
    var id: UUID { piece.id }
}

/// Bolts match on remaining yardage and width.
/// Scraps match on their own width and length, either orientation.
/// A close match fails only one of those checks and still has cloth left.
enum EnoughFabricMatcher {
    static let tolerance = 0.000_001

    static func classify(need: PieceNeed, pieces: [ShelfPiece]) -> (covers: [FabricMatch], close: [FabricMatch]) {
        guard need.isPositive else { return ([], []) }
        var covers: [FabricMatch] = []
        var close: [FabricMatch] = []
        for piece in pieces {
            guard let match = match(need: need, piece: piece) else { continue }
            switch match.kind {
            case .covers:
                covers.append(match)
            case .short:
                close.append(match)
            }
        }
        covers.sort { $0.piece.name.localizedStandardCompare($1.piece.name) == .orderedAscending }
        close.sort { ratio(of: $0, need: need) < ratio(of: $1, need: need) }
        return (covers, close)
    }

    static func match(need: PieceNeed, piece: ShelfPiece) -> FabricMatch? {
        guard need.isPositive else { return nil }
        if piece.isScrap {
            return matchScrap(need: need, piece: piece)
        }
        return matchBolt(need: need, piece: piece)
    }

    private static func matchBolt(need: PieceNeed, piece: ShelfPiece) -> FabricMatch? {
        let widthOK = covers(piece.widthInches, need: need.widthInches)
        let yardsOK = covers(piece.remainingYards, need: need.yards)
        if widthOK && yardsOK {
            return FabricMatch(piece: piece, kind: .covers)
        }
        if widthOK && piece.remainingYards > tolerance {
            let short = need.yards - piece.remainingYards
            if short > tolerance {
                return FabricMatch(piece: piece, kind: .short(.yardage(yards: short)))
            }
        }
        if yardsOK && piece.widthInches > tolerance {
            let short = need.widthInches - piece.widthInches
            if short > tolerance {
                return FabricMatch(piece: piece, kind: .short(.width(inches: short)))
            }
        }
        return nil
    }

    private static func matchScrap(need: PieceNeed, piece: ShelfPiece) -> FabricMatch? {
        let needLength = need.lengthInches
        let orientations = [
            (piece.scrapWidthInches, piece.scrapLengthInches),
            (piece.scrapLengthInches, piece.scrapWidthInches)
        ]
        var bestShort: Double?
        for (haveWidth, haveLength) in orientations {
            let widthOK = covers(haveWidth, need: need.widthInches)
            let lengthOK = covers(haveLength, need: needLength)
            if widthOK && lengthOK {
                return FabricMatch(piece: piece, kind: .covers)
            }
            if widthOK && haveLength > tolerance {
                let short = needLength - haveLength
                let closer = bestShort.map { short < $0 } ?? true
                if short > tolerance && closer {
                    bestShort = short
                }
            }
        }
        if let bestShort {
            return FabricMatch(piece: piece, kind: .short(.scrapEdge(inches: bestShort)))
        }
        return nil
    }

    private static func covers(_ have: Double, need: Double) -> Bool {
        have.isFinite && have + tolerance >= need
    }

    private static func ratio(of match: FabricMatch, need: PieceNeed) -> Double {
        guard case .short(let shortfall) = match.kind else { return 0 }
        switch shortfall {
        case .yardage(let yards):
            return need.yards > 0 ? yards / need.yards : yards
        case .width(let inches):
            return need.widthInches > 0 ? inches / need.widthInches : inches
        case .scrapEdge(let inches):
            let length = need.lengthInches
            return length > 0 ? inches / length : inches
        }
    }
}
