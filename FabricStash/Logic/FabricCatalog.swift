import Foundation

enum FabricStructure: String, CaseIterable, Identifiable, Hashable {
    case knit
    case woven

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knit: "Knit"
        case .woven: "Woven"
        }
    }
}

enum FabricType: String, CaseIterable, Identifiable, Hashable {
    case jersey
    case rib
    case scuba
    case spandexBlend
    case denim
    case linen
    case cotton
    case flannel
    case fleece
    case frenchTerry
    case interlock
    case ponte
    case quiltingCotton
    case rayon
    case satin
    case chiffon
    case twill
    case canvas
    case corduroy
    case wool
    case silk
    case lace
    case mesh
    case velvet
    case shirting
    case doubleGauze
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jersey: "Jersey"
        case .rib: "Rib"
        case .scuba: "Scuba"
        case .spandexBlend: "Spandex blend"
        case .denim: "Denim"
        case .linen: "Linen"
        case .cotton: "Cotton"
        case .flannel: "Flannel"
        case .fleece: "Fleece"
        case .frenchTerry: "French terry"
        case .interlock: "Interlock"
        case .ponte: "Ponte"
        case .quiltingCotton: "Quilting cotton"
        case .rayon: "Rayon / viscose"
        case .satin: "Satin"
        case .chiffon: "Chiffon"
        case .twill: "Twill"
        case .canvas: "Canvas"
        case .corduroy: "Corduroy"
        case .wool: "Wool"
        case .silk: "Silk"
        case .lace: "Lace"
        case .mesh: "Mesh"
        case .velvet: "Velvet"
        case .shirting: "Shirting"
        case .doubleGauze: "Double gauze"
        case .custom: "Custom"
        }
    }

    func displayName(custom: String) -> String {
        if self == .custom {
            let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Custom" : trimmed
        }
        return title
    }
}

enum StorageKind: String, CaseIterable, Identifiable, Hashable {
    case bin
    case shelf
    case room

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bin: "Bin"
        case .shelf: "Shelf"
        case .room: "Room"
        }
    }
}

struct FabricSearchRecord: Equatable, Identifiable {
    var id: UUID
    var name: String
    var fiberContent: String
    var type: FabricType
    var stretch: StretchKind
    var colorName: String
    var colorHex: String
    var printPattern: String
    var tags: [String]
    var source: String
    var remainingYards: Double
    var locationID: UUID?
}

enum LocationChoice: Equatable, Hashable {
    case any
    case unassigned
    case id(UUID)
}

struct FabricQuery: Equatable {
    var text: String = ""
    var type: FabricType?
    var stretch: StretchKind?
    var colorFamily: ColorFamily?
    var minimumYards: Double?
    var location: LocationChoice = .any

    var isFiltering: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
            || type != nil
            || stretch != nil
            || colorFamily != nil
            || minimumYards != nil
            || location != .any
    }
}

enum FabricSearch {
    static func matches(_ record: FabricSearchRecord, query: FabricQuery) -> Bool {
        if let type = query.type, record.type != type { return false }
        if let stretch = query.stretch, record.stretch != stretch { return false }
        if let minimum = query.minimumYards, record.remainingYards + 0.000_001 < minimum {
            return false
        }
        switch query.location {
        case .any:
            break
        case .unassigned:
            if record.locationID != nil { return false }
        case .id(let id):
            if record.locationID != id { return false }
        }
        if let family = query.colorFamily {
            guard let actual = ColorNaming.family(hex: record.colorHex), actual == family else {
                return false
            }
        }
        let needle = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        if record.name.localizedStandardContains(needle) { return true }
        if record.fiberContent.localizedStandardContains(needle) { return true }
        if record.source.localizedStandardContains(needle) { return true }
        if record.printPattern.localizedStandardContains(needle) { return true }
        if record.colorName.localizedStandardContains(needle) { return true }
        return record.tags.contains { $0.localizedStandardContains(needle) }
    }
}
