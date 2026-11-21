import Foundation
import SwiftData

@Model
final class Fabric {
    var id: UUID
    var name: String
    var fiberContent: String
    var structureRaw: String
    var typeRaw: String
    var customTypeName: String
    /// Remaining length, in yards. Cuts subtract from this and cannot pass zero.
    var yardage: Double
    /// Usable width of a bolt, in inches. Scraps also keep their own dimensions.
    var widthInches: Double
    var isScrap: Bool
    var scrapWidthInches: Double
    var scrapLengthInches: Double
    var weightGSM: Double?
    var colorName: String
    var colorHex: String
    var printPattern: String
    var stretchCrosswisePercent: Double?
    var stretchLengthwisePercent: Double?
    var stretchKindRaw: String
    var recoveryRaw: String
    var source: String
    /// Empty when no price was entered. Decimal text in a POSIX format.
    var pricePaidStorage: String
    var currencyCode: String
    var prewashed: Bool
    var careNotes: String
    var tags: [String]
    var isSample: Bool
    var createdAt: Date
    var updatedAt: Date

    var location: StorageLocation?

    @Relationship(deleteRule: .cascade, inverse: \FabricPhoto.fabric)
    var photos: [FabricPhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \YardageUse.fabric)
    var uses: [YardageUse] = []

    init(
        id: UUID = UUID(),
        name: String,
        fiberContent: String = "",
        structure: FabricStructure = .woven,
        type: FabricType = .cotton,
        customTypeName: String = "",
        yardage: Double = 0,
        widthInches: Double = 0,
        isScrap: Bool = false,
        scrapWidthInches: Double = 0,
        scrapLengthInches: Double = 0,
        weightGSM: Double? = nil,
        colorName: String = "",
        colorHex: String = "",
        printPattern: String = "",
        stretchCrosswisePercent: Double? = nil,
        stretchLengthwisePercent: Double? = nil,
        stretchKind: StretchKind = .none,
        recovery: Recovery = .untested,
        source: String = "",
        pricePaid: Decimal? = nil,
        currencyCode: String = "USD",
        prewashed: Bool = false,
        careNotes: String = "",
        tags: [String] = [],
        isSample: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        location: StorageLocation? = nil
    ) {
        self.id = id
        self.name = name
        self.fiberContent = fiberContent
        self.structureRaw = structure.rawValue
        self.typeRaw = type.rawValue
        self.customTypeName = customTypeName
        self.yardage = yardage
        self.widthInches = widthInches
        self.isScrap = isScrap
        self.scrapWidthInches = scrapWidthInches
        self.scrapLengthInches = scrapLengthInches
        self.weightGSM = weightGSM
        self.colorName = colorName
        self.colorHex = colorHex
        self.printPattern = printPattern
        self.stretchCrosswisePercent = stretchCrosswisePercent
        self.stretchLengthwisePercent = stretchLengthwisePercent
        self.stretchKindRaw = stretchKind.rawValue
        self.recoveryRaw = recovery.rawValue
        self.source = source
        self.pricePaidStorage = pricePaid?.posixStorageString ?? ""
        self.currencyCode = currencyCode
        self.prewashed = prewashed
        self.careNotes = careNotes
        self.tags = tags
        self.isSample = isSample
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.location = location
        self.photos = []
        self.uses = []
    }

    var structure: FabricStructure {
        get { FabricStructure(rawValue: structureRaw) ?? .woven }
        set { structureRaw = newValue.rawValue }
    }

    var fabricType: FabricType {
        get { FabricType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    var typeTitle: String {
        fabricType.displayName(custom: customTypeName)
    }

    var stretchKind: StretchKind {
        get { StretchKind(rawValue: stretchKindRaw) ?? .none }
        set { stretchKindRaw = newValue.rawValue }
    }

    var recovery: Recovery {
        get { Recovery(rawValue: recoveryRaw) ?? .untested }
        set { recoveryRaw = newValue.rawValue }
    }

    var pricePaid: Decimal? {
        get {
            guard !pricePaidStorage.isEmpty else { return nil }
            return Decimal(string: pricePaidStorage, locale: Locale(identifier: "en_US_POSIX"))
        }
        set { pricePaidStorage = newValue?.posixStorageString ?? "" }
    }

    var orderedPhotos: [FabricPhoto] {
        photos.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder { return lhs.createdAt < rhs.createdAt }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    var recordedUseYards: Double {
        uses.reduce(0) { $0 + $1.yards }
    }

    var piece: ShelfPiece {
        ShelfPiece(
            id: id,
            name: name,
            remainingYards: yardage,
            widthInches: widthInches,
            isScrap: isScrap,
            scrapWidthInches: scrapWidthInches,
            scrapLengthInches: scrapLengthInches
        )
    }

    var searchRecord: FabricSearchRecord {
        FabricSearchRecord(
            id: id,
            name: name,
            fiberContent: fiberContent,
            type: fabricType,
            stretch: stretchKind,
            colorName: colorName,
            colorHex: colorHex,
            printPattern: printPattern,
            tags: tags,
            source: source,
            remainingYards: yardage,
            locationID: location?.id
        )
    }

    func exportRow(system: MeasurementSystem) -> FabricExportRow {
        let ounces: String
        if let weightGSM {
            ounces = CSVExport.number(UnitConverter.ozPerSqYard(fromGSM: weightGSM))
        } else {
            ounces = ""
        }
        let length = UnitConverter.displayLength(yardage, unit: system.lengthUnit)
        let width = UnitConverter.displayWidth(widthInches, unit: system.widthUnit)
        let scrapWidth = UnitConverter.displayWidth(scrapWidthInches, unit: system.widthUnit)
        let scrapLength = UnitConverter.displayWidth(scrapLengthInches, unit: system.widthUnit)
        let used = UnitConverter.displayLength(recordedUseYards, unit: system.lengthUnit)
        return FabricExportRow(
            name: name,
            fiberContent: fiberContent,
            structure: structure.title,
            type: typeTitle,
            yardageOnHand: CSVExport.number(length),
            width: CSVExport.number(width),
            isScrap: isScrap ? "yes" : "no",
            scrapWidth: isScrap ? CSVExport.number(scrapWidth) : "",
            scrapLength: isScrap ? CSVExport.number(scrapLength) : "",
            weightGSM: weightGSM.map(CSVExport.number) ?? "",
            weightOzPerSqYd: ounces,
            colorName: colorName,
            colorHex: colorHex,
            printPattern: printPattern,
            stretchCrosswisePercent: stretchCrosswisePercent.map(CSVExport.number) ?? "",
            stretchLengthwisePercent: stretchLengthwisePercent.map(CSVExport.number) ?? "",
            stretch: stretchKind.title,
            recovery: recovery.title,
            source: source,
            pricePaid: pricePaidStorage,
            currencyCode: currencyCode,
            prewashed: prewashed ? "yes" : "no",
            careNotes: careNotes,
            tags: tags.joined(separator: "; "),
            storageLocation: location?.name ?? "",
            storageKind: location?.kind.title ?? "",
            createdAt: CSVExport.iso(createdAt),
            updatedAt: CSVExport.iso(updatedAt),
            recordedUse: CSVExport.number(used)
        )
    }
}

@Model
final class FabricPhoto {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var sortOrder: Int
    var createdAt: Date
    var fabric: Fabric?

    init(id: UUID = UUID(), imageData: Data, sortOrder: Int, createdAt: Date = .now) {
        self.id = id
        self.imageData = imageData
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

@Model
final class StorageLocation {
    var id: UUID
    var name: String
    var kindRaw: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Fabric.location)
    var fabrics: [Fabric] = []

    init(id: UUID = UUID(), name: String, kind: StorageKind, sortOrder: Int) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.sortOrder = sortOrder
        self.fabrics = []
    }

    var kind: StorageKind {
        get { StorageKind(rawValue: kindRaw) ?? .bin }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class Project {
    var id: UUID
    var name: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \YardageUse.project)
    var uses: [YardageUse] = []

    init(id: UUID = UUID(), name: String, notes: String = "", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.uses = []
    }

    var totalYards: Double {
        uses.reduce(0) { $0 + $1.yards }
    }
}

@Model
final class YardageUse {
    var id: UUID
    var yards: Double
    var note: String
    var createdAt: Date
    var fabric: Fabric?
    var project: Project?

    init(
        id: UUID = UUID(),
        yards: Double,
        note: String = "",
        createdAt: Date = .now,
        fabric: Fabric? = nil,
        project: Project? = nil
    ) {
        self.id = id
        self.yards = yards
        self.note = note
        self.createdAt = createdAt
        self.fabric = fabric
        self.project = project
    }
}
