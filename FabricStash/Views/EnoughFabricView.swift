import SwiftData
import SwiftUI
import UIKit

struct EnoughFabricView: View {
    @Environment(UnitSettings.self) private var units
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Fabric.name) private var fabrics: [Fabric]

    @State private var lengthText = ""
    @State private var widthText = ""

    private var need: PieceNeed? {
        guard let yards = units.yards(fromDisplay: lengthText),
              let inches = units.inches(fromDisplay: widthText),
              yards > 0, inches > 0 else { return nil }
        return PieceNeed(yards: yards, widthInches: inches)
    }

    private var result: (covers: [FabricMatch], close: [FabricMatch]) {
        guard let need else { return ([], []) }
        return EnoughFabricMatcher.classify(need: need, pieces: fabrics.map(\.piece))
    }

    var body: some View {
        List {
            Section {
                TextField("Length needed (\(units.lengthUnit.abbreviation))", text: $lengthText)
                    .keyboardType(.decimalPad)
                TextField("Width needed (\(units.widthUnit.abbreviation))", text: $widthText)
                    .keyboardType(.decimalPad)
                Text("Bolts need enough length left and a wide enough piece. Scraps are checked on their own width and length, turned if that fits better.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            } header: {
                Text("What the pattern asks for")
            }

            if lengthText.isEmpty && widthText.isEmpty {
                Section {
                    Text("Enter a length and a width. \(AppIdentity.displayName) will list cloth that covers it, and cloth that is close but short.")
                        .foregroundStyle(Studio.inkSecondary)
                }
            } else if need == nil {
                Section {
                    Text("Use numbers greater than zero for both length and width.")
                        .foregroundStyle(Studio.madder)
                }
            } else {
                Section {
                    if result.covers.isEmpty {
                        Text("Nothing on the shelf covers this.")
                            .foregroundStyle(Studio.inkSecondary)
                    } else {
                        ForEach(result.covers) { match in
                            matchRow(match)
                        }
                    }
                } header: {
                    Text("Enough")
                }
                Section {
                    if result.close.isEmpty {
                        Text("No close matches.")
                            .foregroundStyle(Studio.inkSecondary)
                    } else {
                        ForEach(result.close) { match in
                            matchRow(match)
                        }
                    }
                } header: {
                    Text("Close, but short")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Do I have enough?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
    }

    private func matchRow(_ match: FabricMatch) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(match.piece.name)
                .foregroundStyle(Studio.ink)
            Text(detail(match))
                .font(.subheadline)
                .foregroundStyle(Studio.inkSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func detail(_ match: FabricMatch) -> String {
        let piece = match.piece
        let onHand = piece.isScrap
            ? "Scrap \(units.formatWidth(inches: piece.scrapWidthInches)) × \(units.formatWidth(inches: piece.scrapLengthInches))"
            : "\(units.formatLength(yards: piece.remainingYards)) left, \(units.formatWidth(inches: piece.widthInches)) wide"
        switch match.kind {
        case .covers:
            return "\(onHand). Covers this cut."
        case .short(let shortfall):
            return "\(onHand). \(shortfallText(shortfall))"
        }
    }

    private func shortfallText(_ shortfall: FabricShortfall) -> String {
        switch shortfall {
        case .yardage(let yards):
            return "Short by \(units.formatLength(yards: yards))."
        case .width(let inches):
            return "Narrow by \(units.formatWidth(inches: inches))."
        case .scrapEdge(let inches):
            return "Short by \(units.formatWidth(inches: inches)) along the scrap."
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
