import SwiftData
import SwiftUI

struct FabricDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var units
    @Query private var fabrics: [Fabric]
    var fabricID: UUID

    @State private var showEditor = false
    @State private var showUse = false
    @State private var showStretch = false
    @State private var showDelete = false

    private var fabric: Fabric? {
        fabrics.first { $0.id == fabricID }
    }

    var body: some View {
        Group {
            if let fabric {
                detail(fabric)
            } else {
                ContentUnavailableView(
                    "That fabric is gone",
                    systemImage: "scissors",
                    description: Text("It was deleted from this device.")
                )
                .studioScreen()
            }
        }
        .navigationTitle(fabric?.name ?? "Fabric")
        .navigationBarTitleDisplayMode(.inline)
        .studioScreen()
    }

    private func detail(_ fabric: Fabric) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photos(fabric)
                if fabric.isSample {
                    Text("This is sample cloth, invented for screenshots and practice. It is not from your shelf.")
                        .font(.subheadline)
                        .foregroundStyle(Studio.ink)
                        .studioCard()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(fabric.name)
                        .font(Studio.serif(.largeTitle, weight: .semibold))
                        .foregroundStyle(Studio.ink)
                    Text(headlineAmount(fabric))
                        .font(.title3)
                        .foregroundStyle(Studio.ink)
                }
                colorRow(fabric)
                facts(fabric)
                history(fabric)
                VStack(spacing: 10) {
                    Button("Mark yardage used") { showUse = true }
                        .buttonStyle(MadderButtonStyle())
                    Button("Walk through a stretch test") { showStretch = true }
                        .buttonStyle(GreenButtonStyle())
                    Button("Edit fabric") { showEditor = true }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    Button("Delete fabric", role: .destructive) { showDelete = true }
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                FabricEditorView(mode: .edit(fabric.id))
            }
        }
        .sheet(isPresented: $showUse) {
            NavigationStack {
                UseYardageView(fabric: fabric)
            }
        }
        .sheet(isPresented: $showStretch) {
            StretchGuideView { result in
                fabric.stretchCrosswisePercent = result.crosswisePercent
                fabric.stretchLengthwisePercent = result.lengthwisePercent
                fabric.stretchKind = result.kind
                fabric.recovery = result.recovery
                fabric.updatedAt = .now
            }
        }
        .confirmationDialog(
            "Delete \(fabric.name)?",
            isPresented: $showDelete,
            titleVisibility: .visible
        ) {
            Button("Delete fabric", role: .destructive) {
                modelContext.delete(fabric)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Photos and recorded cuts for this fabric go with it. This frees a spot on the free shelf.")
        }
    }

    @ViewBuilder
    private func photos(_ fabric: Fabric) -> some View {
        let ordered = fabric.orderedPhotos
        if ordered.isEmpty {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: fabric.colorHex) ?? Studio.sewingGreen.opacity(0.3))
                .frame(height: 220)
                .accessibilityLabel(fabric.colorName.isEmpty ? "No photo" : "No photo. Color \(fabric.colorName)")
        } else {
            TabView {
                ForEach(ordered) { photo in
                    photoImage(photo)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 280)
            .accessibilityLabel("Photos, \(ordered.count)")
        }
    }

    @ViewBuilder
    private func photoImage(_ photo: FabricPhoto) -> some View {
        if let image = ThumbnailCache.shared.image(id: photo.id, data: photo.imageData, maxPixel: 1200) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("Fabric photo")
        }
    }

    private func colorRow(_ fabric: Fabric) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: fabric.colorHex) ?? Studio.inkSecondary)
                .frame(width: 28, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(Studio.ink.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel(fabric.colorName.isEmpty ? "Color swatch" : "Color \(fabric.colorName)")
            VStack(alignment: .leading, spacing: 2) {
                Text(fabric.colorName.isEmpty ? "No color name" : fabric.colorName)
                    .foregroundStyle(Studio.ink)
                Text(fabric.colorHex.isEmpty ? "No hex" : fabric.colorHex)
                    .font(.subheadline)
                    .foregroundStyle(Studio.inkSecondary)
            }
            Spacer()
            Text(fabric.printPattern.isEmpty ? "No print noted" : fabric.printPattern)
                .font(.subheadline)
                .foregroundStyle(Studio.ink)
                .multilineTextAlignment(.trailing)
        }
        .studioCard()
    }

    private func facts(_ fabric: Fabric) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FactRow(label: "Fiber", value: fabric.fiberContent.isEmpty ? "Not noted" : fabric.fiberContent)
            FactRow(label: "Structure", value: fabric.structure.title)
            FactRow(label: "Type", value: fabric.typeTitle)
            if fabric.isScrap {
                FactRow(
                    label: "Scrap size",
                    value: "\(units.formatWidth(inches: fabric.scrapWidthInches)) by \(units.formatWidth(inches: fabric.scrapLengthInches))"
                )
            } else {
                FactRow(label: "Width", value: units.formatWidth(inches: fabric.widthInches))
            }
            if let gsm = fabric.weightGSM {
                FactRow(
                    label: "Weight",
                    value: "\(NumberParsing.string(gsm, fractionDigits: 0)) GSM · \(NumberParsing.string(UnitConverter.ozPerSqYard(fromGSM: gsm))) oz/yd²"
                )
            }
            FactRow(label: "Stretch", value: stretchLine(fabric))
            FactRow(label: "Recovery", value: fabric.recovery.title)
            FactRow(label: "Source", value: fabric.source.isEmpty ? "Not noted" : fabric.source)
            if let price = priceLabel(amount: fabric.pricePaid, code: fabric.currencyCode) {
                FactRow(label: "Price paid", value: price)
            }
            FactRow(label: "Prewashed", value: fabric.prewashed ? "Yes" : "Not yet")
            if !fabric.careNotes.isEmpty {
                FactRow(label: "Care", value: fabric.careNotes)
            }
            if !fabric.tags.isEmpty {
                FactRow(label: "Tags", value: fabric.tags.joined(separator: ", "))
            }
            FactRow(
                label: "Location",
                value: fabric.location.map { "\($0.kind.title) · \($0.name)" } ?? "No location yet"
            )
            FactRow(label: "Recorded as used", value: units.formatLength(yards: fabric.recordedUseYards))
        }
        .studioCard()
    }

    private func history(_ fabric: Fabric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cuts")
                .font(Studio.serif(.title3, weight: .semibold))
                .foregroundStyle(Studio.ink)
            if fabric.uses.isEmpty {
                Text("No yardage has been marked used yet.")
                    .foregroundStyle(Studio.inkSecondary)
            } else {
                ForEach(fabric.uses.sorted { $0.createdAt > $1.createdAt }) { use in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(units.formatLength(yards: use.yards))
                            .foregroundStyle(Studio.ink)
                        Text(use.project?.name ?? "No project")
                            .font(.subheadline)
                            .foregroundStyle(Studio.inkSecondary)
                        if !use.note.isEmpty {
                            Text(use.note)
                                .font(.subheadline)
                                .foregroundStyle(Studio.ink)
                        }
                        Button("Remove this cut") {
                            remove(use, from: fabric)
                        }
                        .font(.subheadline)
                        .accessibilityHint("Puts the yardage back on this fabric")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .studioCard()
    }

    private func headlineAmount(_ fabric: Fabric) -> String {
        if fabric.isScrap {
            let size = "\(units.formatWidth(inches: fabric.scrapWidthInches)) × \(units.formatWidth(inches: fabric.scrapLengthInches)) scrap"
            if fabric.yardage > 0 {
                return "\(units.formatLength(yards: fabric.yardage)) on hand · \(size)"
            }
            return size
        }
        if fabric.yardage <= 0 {
            return "Nothing left on hand"
        }
        return "\(units.formatLength(yards: fabric.yardage)) on hand · \(units.formatWidth(inches: fabric.widthInches)) wide"
    }

    private func stretchLine(_ fabric: Fabric) -> String {
        let crosswise = fabric.stretchCrosswisePercent.map { "\(NumberParsing.string($0))% crosswise" }
        let lengthwise = fabric.stretchLengthwisePercent.map { "\(NumberParsing.string($0))% lengthwise" }
        let percents = [crosswise, lengthwise].compactMap { $0 }.joined(separator: ", ")
        if percents.isEmpty { return fabric.stretchKind.title }
        return "\(fabric.stretchKind.title) · \(percents)"
    }

    private func remove(_ use: YardageUse, from fabric: Fabric) {
        fabric.yardage = YardageLedger.restore(remainingYards: fabric.yardage, usedYards: use.yards)
        fabric.updatedAt = .now
        modelContext.delete(use)
    }
}
