import Foundation
import SwiftData

@MainActor
enum SampleFabrics {
    static func hasSamples(in context: ModelContext) throws -> Bool {
        let fabrics = try context.fetch(FetchDescriptor<Fabric>())
        return fabrics.contains(where: \.isSample)
    }

    static func load(into context: ModelContext) throws {
        let fabrics = try context.fetch(FetchDescriptor<Fabric>())
        guard !fabrics.contains(where: \.isSample) else { return }

        let bin = StorageLocation(name: "Sample bin", kind: .bin, sortOrder: 0)
        let shelf = StorageLocation(name: "Sample shelf", kind: .shelf, sortOrder: 1)
        context.insert(bin)
        context.insert(shelf)

        let now = Date.now
        let note = "Fictional cloth for trying \(AppIdentity.displayName). It is not from your shelf. Delete it anytime."

        let gingham = make(
            name: "Sample: Picnic Gingham",
            fiber: "100% cotton",
            structure: .woven,
            type: .quiltingCotton,
            yardage: 2.5,
            width: 44,
            gsm: 145,
            colorName: "Red",
            hex: "#B4332A",
            print: "large red gingham",
            source: "Sample Dry Goods",
            price: Decimal(string: "12.50"),
            prewashed: true,
            tags: ["sample", "cotton", "gingham"],
            care: note,
            createdAt: now.addingTimeInterval(-8 * 86_400),
            location: shelf
        )
        let jersey = make(
            name: "Sample: Sea Glass Jersey",
            fiber: "95% cotton, 5% elastane",
            structure: .knit,
            type: .jersey,
            yardage: 2.25,
            width: 60,
            gsm: 180,
            colorName: "Teal",
            hex: "#2F6F6A",
            print: "solid",
            stretchCrosswise: 60,
            stretchLengthwise: 40,
            stretch: .fourWay,
            recovery: .good,
            source: "Sample Knit Co",
            price: Decimal(string: "18"),
            tags: ["sample", "jersey", "knit"],
            care: note,
            createdAt: now.addingTimeInterval(-7 * 86_400),
            location: bin
        )
        let denim = make(
            name: "Sample: Studio Denim",
            fiber: "100% cotton",
            structure: .woven,
            type: .denim,
            yardage: 1.75,
            width: 58,
            gsm: 310,
            colorName: "Navy",
            hex: "#1E2A4A",
            print: "solid",
            source: "Sample Mill",
            price: Decimal(string: "24"),
            tags: ["sample", "denim"],
            care: note,
            createdAt: now.addingTimeInterval(-6 * 86_400),
            location: shelf
        )
        let scrap = make(
            name: "Sample: Madder Linen Scrap",
            fiber: "100% linen",
            structure: .woven,
            type: .linen,
            yardage: 0.3,
            width: 18,
            gsm: 185,
            colorName: "Madder",
            hex: "#9C4A32",
            print: "solid",
            isScrap: true,
            scrapWidth: 18,
            scrapLength: 22,
            tags: ["sample", "scrap", "linen"],
            care: note + " Matched by its 18 by 22 inch size, not as a bolt.",
            createdAt: now.addingTimeInterval(-5 * 86_400),
            location: bin
        )
        let rib = make(
            name: "Sample: Rib Cuff",
            fiber: "98% cotton, 2% elastane",
            structure: .knit,
            type: .rib,
            yardage: 0.75,
            width: 24,
            gsm: 280,
            colorName: "Black",
            hex: "#1A1614",
            print: "solid",
            stretchCrosswise: 80,
            stretchLengthwise: 10,
            stretch: .twoWay,
            recovery: .good,
            tags: ["sample", "rib"],
            care: note,
            createdAt: now.addingTimeInterval(-4 * 86_400),
            location: bin
        )
        let scuba = make(
            name: "Sample: Imaginary Scuba",
            fiber: "polyester and elastane blend",
            structure: .knit,
            type: .scuba,
            yardage: 1.5,
            width: 58,
            gsm: 310,
            colorName: "Purple",
            hex: "#5E3A6B",
            print: "solid",
            stretchCrosswise: 40,
            stretchLengthwise: 35,
            stretch: .fourWay,
            recovery: .poor,
            source: "Sample Activewear",
            price: Decimal(string: "16"),
            tags: ["sample", "scuba"],
            care: note,
            createdAt: now.addingTimeInterval(-3 * 86_400),
            location: bin
        )
        let spandex = make(
            name: "Sample: Costume Spandex",
            fiber: "80% nylon, 20% elastane",
            structure: .knit,
            type: .spandexBlend,
            yardage: 1,
            width: 60,
            gsm: 200,
            colorName: "Gold",
            hex: "#C6A15B",
            print: "tiny stars",
            stretchCrosswise: 100,
            stretchLengthwise: 90,
            stretch: .fourWay,
            recovery: .good,
            source: "Sample Costume Cloth",
            price: Decimal(string: "14.00"),
            tags: ["sample", "spandex", "stars"],
            care: note,
            createdAt: now.addingTimeInterval(-2 * 86_400),
            location: shelf
        )
        let flannel = make(
            name: "Sample: Fiction Flannel",
            fiber: "100% cotton",
            structure: .woven,
            type: .flannel,
            yardage: 4,
            width: 42,
            gsm: 170,
            colorName: "Sage",
            hex: "#8AA58B",
            print: "scattered pine trees",
            source: "Sample Flannel Works",
            price: Decimal(string: "9.75"),
            prewashed: true,
            tags: ["sample", "flannel"],
            care: note,
            createdAt: now.addingTimeInterval(-86_400),
            location: shelf
        )

        for fabric in [gingham, jersey, denim, scrap, rib, scuba, spandex, flannel] {
            context.insert(fabric)
            let photo = FabricPhoto(imageData: PhotoEncoding.solidJPEG(hex: fabric.colorHex), sortOrder: 0)
            photo.fabric = fabric
            context.insert(photo)
        }

        let project = Project(
            name: "Sample: Practice tote",
            notes: "Fictional project. Half a yard is already marked used on the gingham.",
            createdAt: now.addingTimeInterval(-86_400)
        )
        context.insert(project)
        let use = YardageUse(yards: 0.5, note: "Sample cut for the tote body", fabric: gingham, project: project)
        context.insert(use)
        try context.save()
    }

    static func remove(from context: ModelContext) throws {
        let fabrics = try context.fetch(FetchDescriptor<Fabric>())
        for fabric in fabrics where fabric.isSample {
            context.delete(fabric)
        }
        let projects = try context.fetch(FetchDescriptor<Project>())
        for project in projects where project.name.hasPrefix("Sample:") && project.uses.allSatisfy { $0.fabric?.isSample != false } {
            context.delete(project)
        }
        let locations = try context.fetch(FetchDescriptor<StorageLocation>())
        for location in locations where location.name.hasPrefix("Sample ") && location.fabrics.allSatisfy(\.isSample) {
            context.delete(location)
        }
        try context.save()
    }

    private static func make(
        name: String,
        fiber: String,
        structure: FabricStructure,
        type: FabricType,
        yardage: Double,
        width: Double,
        gsm: Double,
        colorName: String,
        hex: String,
        print: String,
        stretchCrosswise: Double? = nil,
        stretchLengthwise: Double? = nil,
        stretch: StretchKind = .none,
        recovery: Recovery = .untested,
        source: String = "",
        price: Decimal? = nil,
        prewashed: Bool = false,
        isScrap: Bool = false,
        scrapWidth: Double = 0,
        scrapLength: Double = 0,
        tags: [String],
        care: String,
        createdAt: Date,
        location: StorageLocation
    ) -> Fabric {
        let fabric = Fabric(
            name: name,
            fiberContent: fiber,
            structure: structure,
            type: type,
            yardage: yardage,
            widthInches: width,
            isScrap: isScrap,
            scrapWidthInches: scrapWidth,
            scrapLengthInches: scrapLength,
            weightGSM: gsm,
            colorName: colorName,
            colorHex: hex,
            printPattern: print,
            stretchCrosswisePercent: stretchCrosswise,
            stretchLengthwisePercent: stretchLengthwise,
            stretchKind: stretch,
            recovery: recovery,
            source: source,
            pricePaid: price,
            prewashed: prewashed,
            careNotes: care,
            tags: tags,
            isSample: true,
            createdAt: createdAt,
            updatedAt: createdAt,
            location: location
        )
        return fabric
    }
}
