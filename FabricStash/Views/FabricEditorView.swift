import PhotosUI
import SwiftData
import SwiftUI
import UIKit

enum FabricEditorMode {
    case create
    case edit(UUID)
}

struct PhotoDraft: Identifiable, Equatable {
    var id: UUID
    var data: Data
}

struct FabricDraft {
    var name = ""
    var fiberContent = ""
    var structure: FabricStructure = .woven
    var type: FabricType = .cotton
    var customTypeName = ""
    var yardageText = ""
    var widthText = ""
    var isScrap = false
    var scrapWidthText = ""
    var scrapLengthText = ""
    var gsmText = ""
    var ozText = ""
    var colorName = ""
    var colorHex = ""
    var printPattern = ""
    var stretchCrosswiseText = ""
    var stretchLengthwiseText = ""
    var stretchKind: StretchKind = .none
    var recovery: Recovery = .untested
    var source = ""
    var priceText = ""
    var currencyCode = "USD"
    var prewashed = false
    var careNotes = ""
    var tagsText = ""
    var locationID: UUID?
    var photos: [PhotoDraft] = []
    var isSample = false
    var loadedYardage: Double?
    var loadedWidth: Double?
    var loadedScrapWidth: Double?
    var loadedScrapLength: Double?

    init() {}

    @MainActor
    init(fabric: Fabric, units: UnitSettings) {
        name = fabric.name
        fiberContent = fabric.fiberContent
        structure = fabric.structure
        type = fabric.fabricType
        customTypeName = fabric.customTypeName
        yardageText = units.lengthField(yards: fabric.yardage)
        widthText = units.widthField(inches: fabric.widthInches)
        isScrap = fabric.isScrap
        scrapWidthText = fabric.scrapWidthInches > 0 ? units.widthField(inches: fabric.scrapWidthInches) : ""
        scrapLengthText = fabric.scrapLengthInches > 0 ? units.widthField(inches: fabric.scrapLengthInches) : ""
        if let gsm = fabric.weightGSM {
            gsmText = NumberParsing.string(gsm, fractionDigits: 1)
            ozText = NumberParsing.string(UnitConverter.ozPerSqYard(fromGSM: gsm))
        }
        colorName = fabric.colorName
        colorHex = fabric.colorHex
        printPattern = fabric.printPattern
        if let value = fabric.stretchCrosswisePercent {
            stretchCrosswiseText = NumberParsing.string(value)
        }
        if let value = fabric.stretchLengthwisePercent {
            stretchLengthwiseText = NumberParsing.string(value)
        }
        stretchKind = fabric.stretchKind
        recovery = fabric.recovery
        source = fabric.source
        priceText = fabric.pricePaid?.posixStorageString ?? ""
        currencyCode = fabric.currencyCode
        prewashed = fabric.prewashed
        careNotes = fabric.careNotes
        tagsText = fabric.tags.joined(separator: ", ")
        locationID = fabric.location?.id
        photos = fabric.orderedPhotos.map { PhotoDraft(id: $0.id, data: $0.imageData) }
        isSample = fabric.isSample
        loadedYardage = fabric.yardage
        loadedWidth = fabric.widthInches
        loadedScrapWidth = fabric.scrapWidthInches
        loadedScrapLength = fabric.scrapLengthInches
    }
}

struct FabricEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var units
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: \Fabric.updatedAt) private var allFabrics: [Fabric]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    var mode: FabricEditorMode

    @State private var draft = FabricDraft()
    @State private var didLoad = false
    @State private var libraryItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showStretch = false
    @State private var showPaywall = false
    @State private var samplePoint: CGPoint?
    @State private var automaticColorName: String?
    @State private var saveError: String?
    @State private var newLocationName = ""
    @State private var newLocationKind: StorageKind = .bin
    @FocusState private var focus: EditorField?

    private enum EditorField: Hashable {
        case name, fiber, customType, yardage, width, scrapWidth, scrapLength
        case gsm, oz, colorName, printPattern
        case crosswise, lengthwise, source, price, currency, care, tags, newLocation
    }

    var body: some View {
        Form {
            photoSection
            identitySection
            amountSection
            weightSection
            stretchSection
            sourceSection
            locationSection
            if let reason = saveBlockReason {
                Section {
                    Text(reason)
                        .foregroundStyle(Studio.caution)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(saveBlockReason != nil)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onChange(of: draft.gsmText) { _, newValue in
            guard focus == .gsm else { return }
            syncOunces(fromGSM: newValue)
        }
        .onChange(of: draft.ozText) { _, newValue in
            guard focus == .oz else { return }
            syncGSM(fromOunces: newValue)
        }
        .onChange(of: libraryItems) { _, items in
            guard !items.isEmpty else { return }
            let incoming = items
            libraryItems = []
            Task { await importLibrary(incoming) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                adoptPhotos([PhotoDraft(id: UUID(), data: data)])
            }
        }
        .sheet(isPresented: $showStretch) {
            StretchGuideView { result in
                draft.stretchCrosswiseText = NumberParsing.string(result.crosswisePercent)
                draft.stretchLengthwiseText = NumberParsing.string(result.lengthwisePercent)
                draft.stretchKind = result.kind
                draft.recovery = result.recovery
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Could not save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var title: String {
        switch mode {
        case .create: "New fabric"
        case .edit: "Edit fabric"
        }
    }

    private var photoSection: some View {
        Section {
            if let photo = draft.photos.first, let image = UIImage(data: photo.data) {
                ColorSamplerView(image: image, point: $samplePoint) { rgb in
                    applySample(rgb)
                }
                Text("Tap the cloth. That spot is this fabric’s color, and this photo stays with it.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            } else {
                Text("Take a picture of the fabric, then tap the cloth to set its color. Choosing a photo you already have is the other way. One photo does both jobs.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            }
            colorSwatchRow
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take a photo", systemImage: "camera")
                        .font(.body.weight(.semibold))
                }
            } else {
                Text("The camera is available on a device. You can still choose a photo from the library.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            }
            PhotosPicker(selection: $libraryItems, maxSelectionCount: 12, matching: .images) {
                Label("Choose a photo", systemImage: "photo.on.rectangle")
            }
            if !draft.photos.isEmpty {
                ForEach(Array(draft.photos.enumerated()), id: \.element.id) { index, photo in
                    photoRow(photo, index: index)
                }
            }
            TextField("Print or pattern", text: $draft.printPattern, prompt: Text("solid, gingham, ditsy floral"))
                .focused($focus, equals: .printPattern)
        } header: {
            Text("Photo and color")
        }
    }

    private var colorSwatchRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: draft.colorHex) ?? Studio.paper)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Studio.ink.opacity(0.15), lineWidth: 1)
                )
                .accessibilityLabel(swatchLabel)
            TextField("Color name", text: $draft.colorName, prompt: Text("Name, if you want one"))
                .focused($focus, equals: .colorName)
        }
    }

    private var swatchLabel: String {
        if draft.colorHex.isEmpty {
            return "No color sampled yet"
        }
        if draft.colorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Sampled color"
        }
        return "Sampled color, \(draft.colorName)"
    }

    private func photoRow(_ photo: PhotoDraft, index: Int) -> some View {
        HStack(spacing: 12) {
            photoThumb(photo)
            VStack(alignment: .leading, spacing: 6) {
                Text(index == 0 ? "Color photo" : "Photo \(index + 1)")
                    .foregroundStyle(Studio.ink)
                HStack(spacing: 4) {
                    Button {
                        movePhoto(photo.id, by: -1)
                    } label: {
                        Image(systemName: "arrow.up")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(index == 0)
                    .accessibilityLabel("Move photo earlier")
                    Button {
                        movePhoto(photo.id, by: 1)
                    } label: {
                        Image(systemName: "arrow.down")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(index == draft.photos.count - 1)
                    .accessibilityLabel("Move photo later")
                    Button(role: .destructive) {
                        deletePhoto(photo.id)
                    } label: {
                        Image(systemName: "trash")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Delete photo")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func photoThumb(_ photo: PhotoDraft) -> some View {
        Group {
            if let image = ThumbnailCache.shared.image(id: photo.id, data: photo.data, maxPixel: 200) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Studio.paper
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityHidden(true)
    }

    private var identitySection: some View {
        Section("Cloth") {
            TextField("Name", text: $draft.name)
                .focused($focus, equals: .name)
            TextField("Fiber content", text: $draft.fiberContent, prompt: Text("100% linen, or 95% cotton 5% elastane"))
                .focused($focus, equals: .fiber)
            Picker("Structure", selection: $draft.structure) {
                ForEach(FabricStructure.allCases) { structure in
                    Text(structure.title).tag(structure)
                }
            }
            Picker("Type", selection: $draft.type) {
                ForEach(FabricType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            if draft.type == .custom {
                TextField("Custom type", text: $draft.customTypeName)
                    .focused($focus, equals: .customType)
            }
        }
    }

    private var measurementKeyboard: UIKeyboardType {
        units.system == .imperial ? .numbersAndPunctuation : .decimalPad
    }

    private var fractionNote: String {
        units.system == .imperial ? " Fractions such as 1/2, 3/8, and 44 1/2 are fine." : ""
    }

    private var scrapAmountNote: String {
        "Scraps are matched on these two sides. Yardage can stay blank.\(fractionNote)"
    }

    private var boltAmountNote: String {
        "On hand is what is left. Mark a cut from the fabric page to tie it to a project. It cannot go below zero.\(fractionNote)"
    }

    private var amountSection: some View {
        Section {
            Toggle("This is a scrap or remnant", isOn: $draft.isScrap)
            TextField("On hand (\(units.lengthUnit.abbreviation))", text: $draft.yardageText)
                .keyboardType(measurementKeyboard)
                .focused($focus, equals: .yardage)
            if draft.isScrap {
                TextField("Scrap width (\(units.widthUnit.abbreviation))", text: $draft.scrapWidthText)
                    .keyboardType(measurementKeyboard)
                    .focused($focus, equals: .scrapWidth)
                TextField("Scrap length (\(units.widthUnit.abbreviation))", text: $draft.scrapLengthText)
                    .keyboardType(measurementKeyboard)
                    .focused($focus, equals: .scrapLength)
                Text(scrapAmountNote)
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            } else {
                TextField("Width (\(units.widthUnit.abbreviation))", text: $draft.widthText)
                    .keyboardType(measurementKeyboard)
                    .focused($focus, equals: .width)
                Text(boltAmountNote)
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            }
        } header: {
            Text("Amount")
        }
    }

    private var weightSection: some View {
        Section {
            TextField("GSM", text: $draft.gsmText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .gsm)
            TextField("Ounces per square yard", text: $draft.ozText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .oz)
            Text("Stored as GSM. 1 oz/yd² = \(NumberParsing.string(UnitConverter.gsmPerOzPerSquareYard, fractionDigits: 3)) GSM.")
                .font(.footnote)
                .foregroundStyle(Studio.inkSecondary)
        } header: {
            Text("Weight")
        }
    }

    private var stretchSection: some View {
        Section {
            TextField("Crosswise stretch %", text: $draft.stretchCrosswiseText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .crosswise)
            TextField("Lengthwise stretch %", text: $draft.stretchLengthwiseText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .lengthwise)
            Picker("Stretch", selection: $draft.stretchKind) {
                ForEach(StretchKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            Picker("Recovery", selection: $draft.recovery) {
                ForEach(Recovery.allCases) { recovery in
                    Text(recovery.title).tag(recovery)
                }
            }
            Button("Walk through a stretch test") { showStretch = true }
            Text(units.system == .imperial
                ? "The guide uses a 4 inch mark and a tape. The phone does not measure stretch."
                : "The guide uses a 10 cm mark and a tape. The phone does not measure stretch.")
                .font(.footnote)
                .foregroundStyle(Studio.inkSecondary)
        } header: {
            Text("Stretch")
        }
    }

    private var sourceSection: some View {
        Section("Where it came from") {
            TextField("Store or source", text: $draft.source)
                .focused($focus, equals: .source)
            TextField("Price paid", text: $draft.priceText)
                .keyboardType(.decimalPad)
                .focused($focus, equals: .price)
            TextField("Currency code", text: $draft.currencyCode)
                .textInputAutocapitalization(.characters)
                .focused($focus, equals: .currency)
            Toggle("Prewashed", isOn: $draft.prewashed)
            TextField("Care notes", text: $draft.careNotes, axis: .vertical)
                .lineLimit(3...6)
                .focused($focus, equals: .care)
            TextField("Tags, separated by commas", text: $draft.tagsText)
                .focused($focus, equals: .tags)
        }
    }

    private var locationSection: some View {
        Section("Location") {
            Picker("Place", selection: $draft.locationID) {
                Text("None").tag(Optional<UUID>.none)
                ForEach(locations) { location in
                    Text("\(location.kind.title) · \(location.name)").tag(Optional(location.id))
                }
            }
            TextField("New location name", text: $newLocationName)
                .focused($focus, equals: .newLocation)
            Picker("Kind", selection: $newLocationKind) {
                ForEach(StorageKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            Button("Add location", action: addLocation)
                .disabled(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var saveBlockReason: String? {
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Give the fabric a name."
        }
        if draft.isScrap {
            guard let width = units.inches(fromDisplay: draft.scrapWidthText), width > 0,
                  let length = units.inches(fromDisplay: draft.scrapLengthText), length > 0 else {
                return "Enter the scrap's width and length."
            }
            if let problem = nonNegativeLength(draft.yardageText, emptyAllowed: true, label: "Yardage") {
                return problem
            }
        } else {
            if let problem = nonNegativeLength(draft.yardageText, emptyAllowed: false, label: "Yardage") {
                return problem
            }
            guard let width = units.inches(fromDisplay: draft.widthText), width > 0 else {
                return "Enter a width greater than zero."
            }
        }
        if let gsm = resolvedGSM() {
            if gsm < 0 { return "Weight cannot be negative." }
        } else if !draft.gsmText.trimmingCharacters(in: .whitespaces).isEmpty || !draft.ozText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Weight should be a number."
        }
        if !draft.priceText.trimmingCharacters(in: .whitespaces).isEmpty && NumberParsing.decimal(from: draft.priceText) == nil {
            return "Price should be a number."
        }
        if NumberParsing.decimal(from: draft.priceText) != nil {
            let code = draft.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
            if code.count != 3 { return "Use a 3-letter currency code, such as USD." }
        }
        if let problem = percentProblem(draft.stretchCrosswiseText, label: "Crosswise stretch") { return problem }
        if let problem = percentProblem(draft.stretchLengthwiseText, label: "Lengthwise stretch") { return problem }
        return nil
    }

    private func nonNegativeLength(_ text: String, emptyAllowed: Bool, label: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return emptyAllowed ? nil : "Enter how much is left, as zero or more." }
        guard let yards = units.yards(fromDisplay: trimmed) else { return "\(label) should be a number." }
        if yards < 0 { return "\(label) cannot go below zero." }
        return nil
    }

    private func percentProblem(_ text: String, label: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = NumberParsing.double(from: trimmed) else { return "\(label) should be a number." }
        if value < 0 { return "\(label) cannot be negative." }
        if value > 500 { return "\(label) is past 500%. Check the measurement." }
        return nil
    }

    private func resolvedGSM() -> Double? {
        if let gsm = NumberParsing.double(from: draft.gsmText) { return gsm }
        if let ounces = NumberParsing.double(from: draft.ozText) {
            return UnitConverter.gsm(fromOzPerSqYard: ounces)
        }
        return nil
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        switch mode {
        case .create:
            draft.currencyCode = Locale.current.currency?.identifier ?? "USD"
        case .edit(let id):
            if let fabric = allFabrics.first(where: { $0.id == id }) {
                draft = FabricDraft(fabric: fabric, units: units)
                if let rgb = RGB(hex: fabric.colorHex), ColorNaming.nearestName(to: rgb) == fabric.colorName {
                    automaticColorName = fabric.colorName
                }
            }
        }
    }

    private func syncOunces(fromGSM text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            draft.ozText = ""
        } else if let gsm = NumberParsing.double(from: trimmed) {
            draft.ozText = NumberParsing.string(UnitConverter.ozPerSqYard(fromGSM: gsm))
        }
    }

    private func syncGSM(fromOunces text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            draft.gsmText = ""
        } else if let ounces = NumberParsing.double(from: trimmed) {
            draft.gsmText = NumberParsing.string(UnitConverter.gsm(fromOzPerSqYard: ounces), fractionDigits: 1)
        }
    }

    private func movePhoto(_ id: UUID, by offset: Int) {
        guard let index = draft.photos.firstIndex(where: { $0.id == id }) else { return }
        let next = index + offset
        guard draft.photos.indices.contains(next) else { return }
        draft.photos.swapAt(index, next)
        if index == 0 || next == 0 {
            samplePoint = nil
        }
    }

    private func deletePhoto(_ id: UUID) {
        let wasFirst = draft.photos.first?.id == id
        draft.photos.removeAll { $0.id == id }
        if wasFirst {
            samplePoint = nil
        }
    }

    private func adoptPhotos(_ added: [PhotoDraft]) {
        let wasEmpty = draft.photos.isEmpty
        draft.photos.append(contentsOf: added)
        if wasEmpty, draft.colorHex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let first = draft.photos.first {
            sampleCenter(of: first)
        }
    }

    private func sampleCenter(of photo: PhotoDraft) {
        guard let image = UIImage(data: photo.data) else { return }
        let center = CGPoint(x: 0.5, y: 0.5)
        samplePoint = center
        if let rgb = PixelSampler.color(in: image, atNormalized: center) {
            applySample(rgb)
        }
    }

    private func applySample(_ rgb: RGB) {
        draft.colorHex = rgb.hex
        let name = ColorNaming.nearestName(to: rgb)
        let current = draft.colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty || current == automaticColorName {
            draft.colorName = name
            automaticColorName = name
        }
    }

    private func importLibrary(_ items: [PhotosPickerItem]) async {
        var added: [PhotoDraft] = []
        for item in items {
            guard let imported = try? await item.loadTransferable(type: ImportedPhoto.self) else { continue }
            let jpeg = await MainActor.run { () -> Data? in
                guard let image = UIImage(data: imported.data) else { return nil }
                return PhotoEncoding.jpegData(from: image)
            }
            if let jpeg {
                added.append(PhotoDraft(id: UUID(), data: jpeg))
            }
        }
        await MainActor.run {
            adoptPhotos(added)
        }
    }

    private func addLocation() {
        let name = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let order = (locations.map(\.sortOrder).max() ?? -1) + 1
        let location = StorageLocation(name: name, kind: newLocationKind, sortOrder: order)
        modelContext.insert(location)
        draft.locationID = location.id
        newLocationName = ""
    }

    private func save() {
        guard saveBlockReason == nil else { return }
        if case .create = mode {
            guard FreeTier.canAddFabric(currentCount: allFabrics.count, isUnlocked: purchases.isUnlocked) else {
                showPaywall = true
                return
            }
        }
        do {
            let fabric: Fabric
            switch mode {
            case .create:
                fabric = Fabric(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines))
                modelContext.insert(fabric)
            case .edit(let id):
                guard let existing = allFabrics.first(where: { $0.id == id }) else {
                    saveError = "That fabric is no longer on this device."
                    return
                }
                fabric = existing
            }
            apply(to: fabric)
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func apply(to fabric: Fabric) {
        fabric.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.fiberContent = draft.fiberContent.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.structure = draft.structure
        fabric.fabricType = draft.type
        fabric.customTypeName = draft.customTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.yardage = units.resolvedYards(text: draft.yardageText, canonical: draft.loadedYardage) ?? 0
        fabric.isScrap = draft.isScrap
        if draft.isScrap {
            fabric.scrapWidthInches = units.resolvedInches(text: draft.scrapWidthText, canonical: draft.loadedScrapWidth) ?? 0
            fabric.scrapLengthInches = units.resolvedInches(text: draft.scrapLengthText, canonical: draft.loadedScrapLength) ?? 0
            fabric.widthInches = fabric.scrapWidthInches
        } else {
            fabric.widthInches = units.resolvedInches(text: draft.widthText, canonical: draft.loadedWidth) ?? 0
            fabric.scrapWidthInches = 0
            fabric.scrapLengthInches = 0
        }
        fabric.weightGSM = resolvedGSM()
        fabric.colorName = draft.colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hex = draft.colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.colorHex = RGB(hex: hex)?.hex ?? ""
        fabric.printPattern = draft.printPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.stretchCrosswisePercent = NumberParsing.double(from: draft.stretchCrosswiseText)
        fabric.stretchLengthwisePercent = NumberParsing.double(from: draft.stretchLengthwiseText)
        fabric.stretchKind = draft.stretchKind
        fabric.recovery = draft.recovery
        fabric.source = draft.source.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.pricePaid = NumberParsing.decimal(from: draft.priceText)
        let currency = draft.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        fabric.currencyCode = currency.isEmpty ? "USD" : currency
        fabric.prewashed = draft.prewashed
        fabric.careNotes = draft.careNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.tags = tags(from: draft.tagsText)
        fabric.location = locations.first { $0.id == draft.locationID }
        if case .create = mode {
            fabric.isSample = false
        }
        fabric.updatedAt = .now
        let existing = Array(fabric.photos)
        let kept = Set(draft.photos.map(\.id))
        for photo in existing where !kept.contains(photo.id) {
            modelContext.delete(photo)
        }
        for (index, photoDraft) in draft.photos.enumerated() {
            if let photo = existing.first(where: { $0.id == photoDraft.id }) {
                photo.sortOrder = index
                photo.imageData = photoDraft.data
            } else {
                let photo = FabricPhoto(id: photoDraft.id, imageData: photoDraft.data, sortOrder: index)
                photo.fabric = fabric
                modelContext.insert(photo)
            }
        }
    }

    private func tags(from text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for part in text.split(separator: ",") {
            let tag = part.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = tag.lowercased()
            guard !tag.isEmpty, seen.insert(key).inserted else { continue }
            result.append(tag)
        }
        return result
    }
}
