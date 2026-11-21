import SwiftData
import SwiftUI

@main
struct FabricStashApp: App {
    @State private var purchases = PurchaseManager()
    @State private var units = UnitSettings()

    init() {
        StudioChrome.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(purchases)
                .environment(units)
                .tint(Studio.madder)
                .task { await purchases.start() }
        }
        .modelContainer(ModelStore.container)
    }
}

enum ModelStore {
    static let container: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .none)
            return try ModelContainer(
                for: Fabric.self,
                FabricPhoto.self,
                StorageLocation.self,
                Project.self,
                YardageUse.self,
                configurations: configuration
            )
        } catch {
            fatalError("\(AppIdentity.displayName) could not open its on-device store: \(error.localizedDescription)")
        }
    }()

    @MainActor
    static let preview: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(
            for: Fabric.self,
            FabricPhoto.self,
            StorageLocation.self,
            Project.self,
            YardageUse.self,
            configurations: configuration
        )
        return container
    }()
}
