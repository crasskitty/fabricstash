import SwiftData
import SwiftUI
import UIKit

struct GalleryView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(UnitSettings.self) private var units
    @Environment(\.openStudioSheet) private var sheets
    @Query(sort: \Fabric.updatedAt, order: .reverse) private var fabrics: [Fabric]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    @Environment(\.modelContext) private var modelContext
    @Binding var selection: UUID?
    var onAdd: () -> Void

    @State private var query = FabricQuery()
    @State private var sampleError: String?
    @State private var showFilters = false
    @State private var width: CGFloat = 390

    private var shown: [Fabric] {
        fabrics.filter { FabricSearch.matches($0.searchRecord, query: query) }
    }

    private var columnCount: Int {
        if width >= 900 { return 4 }
        if width >= 640 { return 3 }
        return 2
    }

    var body: some View {
        Group {
            if fabrics.isEmpty {
                emptyShelf
            } else if shown.isEmpty {
                noMatches
            } else {
                grid
            }
        }
        .navigationTitle(AppIdentity.displayName)
        .navigationBarTitleDisplayMode(.large)
        .studioScreen()
        .searchable(text: $query.text, prompt: "Name, fiber, tag, store, print")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Do I have enough?", systemImage: "ruler") { sheets.enough() }
                    Button("Locations", systemImage: "archivebox") { sheets.locations() }
                    Button("Projects", systemImage: "scissors") { sheets.projects() }
                    ShareLink(
                        item: CSVFile(text: CSVExport.render(rows: fabrics.map { $0.exportRow(system: units.system) }, system: units.system)),
                        preview: SharePreview(AppIdentity.csvFilename)
                    ) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    Button("Settings", systemImage: "gearshape") { sheets.settings() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: query.isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter fabrics")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add fabric")
            }
        }
        .sheet(isPresented: $showFilters) {
            NavigationStack {
                FilterSheet(query: $query, locations: locations)
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .allowsHitTesting(false)
                    .onAppear { width = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        width = newWidth
                    }
            }
        }
        .navigationSplitViewColumnWidth(min: 340, ideal: 720, max: 980)
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                shelfCount
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount),
                    spacing: 12
                ) {
                    ForEach(shown) { fabric in
                        FabricLink(fabricID: fabric.id, selection: $selection) {
                            FabricSwatch(
                                fabric: fabric,
                                units: units,
                                isSelected: selection == fabric.id
                            )
                        }
                        .accessibilityHint("Shows this fabric")
                    }
                }
            }
            .padding(16)
        }
    }

    private var shelfCount: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(countLine)
                .font(.subheadline)
                .foregroundStyle(Studio.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            Button("Do I have enough?", action: sheets.enough)
                .buttonStyle(.bordered)
                .tint(Studio.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countLine: String {
        let visible = shown.count == fabrics.count
            ? "\(fabrics.count) \(fabrics.count == 1 ? "fabric" : "fabrics")"
            : "\(shown.count) of \(fabrics.count)"
        if purchases.isUnlocked {
            return "\(visible) · unlimited"
        }
        return "\(visible) · \(fabrics.count) of \(FreeTier.fabricLimit) on the free shelf"
    }

    private var emptyShelf: some View {
        VStack(spacing: 18) {
            Text("The shelf is empty")
                .font(.title.weight(.semibold))
                .foregroundStyle(Studio.ink)
                .multilineTextAlignment(.center)
            Text("Add a fabric you want to remember, or load a clearly fake set of samples to click around \(AppIdentity.displayName).")
                .font(.body)
                .foregroundStyle(Studio.inkSecondary)
                .multilineTextAlignment(.center)
            Button("Add a fabric", action: onAdd)
                .buttonStyle(AccentButtonStyle())
            Button("Load sample fabrics", action: loadSamples)
                .buttonStyle(QuietButtonStyle())
            Text("Samples are invented cloth for screenshots and practice. They count toward the free \(FreeTier.fabricLimit).")
                .font(.footnote)
                .foregroundStyle(Studio.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: 460)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Could not load samples", isPresented: Binding(
            get: { sampleError != nil },
            set: { if !$0 { sampleError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sampleError ?? "")
        }
    }

    private func loadSamples() {
        do {
            try SampleFabrics.load(into: modelContext)
        } catch {
            sampleError = error.localizedDescription
        }
    }

    private var noMatches: some View {
        VStack(spacing: 14) {
            Text("Nothing matches")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Studio.ink)
            Text("Try another word, or clear the filters.")
                .foregroundStyle(Studio.inkSecondary)
            Button("Clear search and filters") {
                query = FabricQuery()
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FabricLink<Label: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var fabricID: UUID
    @Binding var selection: UUID?
    @ViewBuilder var label: () -> Label

    var body: some View {
        if sizeClass == .compact {
            NavigationLink(value: fabricID) {
                label()
            }
            .buttonStyle(.plain)
        } else {
            Button {
                selection = fabricID
            } label: {
                label()
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FabricSwatch: View {
    var fabric: Fabric
    var units: UnitSettings
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                swatchFace
                    .frame(maxWidth: .infinity)
                    .frame(height: 132)
                    .clipped()
                HStack(spacing: 6) {
                    if fabric.isSample { badge("Sample") }
                    if fabric.isScrap { badge("Scrap") }
                    if !fabric.isScrap && fabric.yardage <= 0 { badge("Used up") }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(fabric.name)
                .font(.headline)
                .foregroundStyle(Studio.ink)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: fabric.colorHex) ?? Studio.inkSecondary)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                Text(amountLine)
                    .font(.subheadline)
                    .foregroundStyle(Studio.ink)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Studio.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Studio.accent : Studio.ink.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var swatchFace: some View {
        if let photo = fabric.orderedPhotos.first,
           let image = ThumbnailCache.shared.image(id: photo.id, data: photo.imageData, maxPixel: 480) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let color = Color(hex: fabric.colorHex) {
            color
        } else {
            Studio.paper
        }
    }

    private func badge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Studio.onAccent)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Studio.accentFill, in: Capsule())
    }

    private var amountLine: String {
        if fabric.isScrap {
            return "\(units.formatWidth(inches: fabric.scrapWidthInches)) × \(units.formatWidth(inches: fabric.scrapLengthInches))"
        }
        return units.formatLength(yards: fabric.yardage)
    }

    private var accessibilityText: String {
        var parts = [fabric.name, amountLine]
        if !fabric.colorName.isEmpty { parts.append(fabric.colorName) }
        if fabric.isSample { parts.append("sample") }
        if fabric.isScrap { parts.append("scrap") }
        return parts.joined(separator: ", ")
    }
}

private struct FilterSheet: View {
    @Environment(UnitSettings.self) private var units
    @Environment(\.dismiss) private var dismiss
    @Binding var query: FabricQuery
    var locations: [StorageLocation]
    @State private var minimumText = ""

    var body: some View {
        Form {
            Section("Cloth") {
                Picker("Type", selection: typeBinding) {
                    Text("Any type").tag(Optional<FabricType>.none)
                    ForEach(FabricType.allCases) { type in
                        Text(type.title).tag(Optional(type))
                    }
                }
                Picker("Stretch", selection: stretchBinding) {
                    Text("Any stretch").tag(Optional<StretchKind>.none)
                    ForEach(StretchKind.allCases) { kind in
                        Text(kind.title).tag(Optional(kind))
                    }
                }
                Picker("Color", selection: colorBinding) {
                    Text("Any color").tag(Optional<ColorFamily>.none)
                    ForEach(ColorFamily.allCases) { family in
                        Text(family.title).tag(Optional(family))
                    }
                }
            }
            Section {
                TextField("Minimum on hand (\(units.lengthUnit.abbreviation))", text: $minimumText)
                    .keyboardType(units.system == .imperial ? .numbersAndPunctuation : .decimalPad)
                Text("Compared with yardage still on the shelf, after cuts.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            } header: {
                Text("Yardage")
            }
            Section("Location") {
                Picker("Place", selection: locationBinding) {
                    Text("Anywhere").tag(LocationChoice.any)
                    Text("No location").tag(LocationChoice.unassigned)
                    ForEach(locations) { location in
                        Text(location.name).tag(LocationChoice.id(location.id))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Clear") { clear() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
        .onAppear {
            if let minimum = query.minimumYards {
                minimumText = units.lengthField(yards: minimum)
            }
        }
        .onChange(of: minimumText) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                query.minimumYards = nil
            } else if let yards = units.yards(fromDisplay: trimmed), yards >= 0 {
                query.minimumYards = yards
            }
        }
    }

    private var typeBinding: Binding<FabricType?> {
        Binding(get: { query.type }, set: { query.type = $0 })
    }

    private var stretchBinding: Binding<StretchKind?> {
        Binding(get: { query.stretch }, set: { query.stretch = $0 })
    }

    private var colorBinding: Binding<ColorFamily?> {
        Binding(get: { query.colorFamily }, set: { query.colorFamily = $0 })
    }

    private var locationBinding: Binding<LocationChoice> {
        Binding(get: { query.location }, set: { query.location = $0 })
    }

    private func clear() {
        query.type = nil
        query.stretch = nil
        query.colorFamily = nil
        query.minimumYards = nil
        query.location = .any
        minimumText = ""
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
