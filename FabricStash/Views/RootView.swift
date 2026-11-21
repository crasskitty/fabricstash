import SwiftData
import SwiftUI

struct IdentifiedFabric: Identifiable {
    let id: UUID
}

struct RootView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: \Fabric.updatedAt, order: .reverse) private var fabrics: [Fabric]
    @State private var selectedID: UUID?
    @State private var showNewFabric = false
    @State private var showPaywall = false
    @State private var openEditorAfterUnlock = false
    @State private var showEnough = false
    @State private var showLocations = false
    @State private var showProjects = false
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            GalleryView(selection: $selectedID, onAdd: attemptAdd)
                .navigationDestination(for: UUID.self) { id in
                    FabricDetailView(fabricID: id)
                }
        } detail: {
            if let selectedID, fabrics.contains(where: { $0.id == selectedID }) {
                FabricDetailView(fabricID: selectedID)
            } else {
                ContentUnavailableView {
                    Label("Choose a fabric", systemImage: "square.grid.2x2")
                } description: {
                    Text("Tap a swatch to see fiber, what is left, and where it lives.")
                }
                .studioScreen()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: fabrics.map(\.id)) { _, ids in
            if let selectedID, !ids.contains(selectedID) {
                self.selectedID = nil
            }
        }
        .onChange(of: purchases.isUnlocked) { _, unlocked in
            guard unlocked, openEditorAfterUnlock else { return }
            openEditorAfterUnlock = false
            showPaywall = false
            showNewFabric = true
        }
        .sheet(isPresented: $showNewFabric) {
            NavigationStack {
                FabricEditorView(mode: .create)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showEnough) {
            NavigationStack {
                EnoughFabricView()
            }
        }
        .sheet(isPresented: $showLocations) {
            NavigationStack {
                LocationsView()
            }
        }
        .sheet(isPresented: $showProjects) {
            NavigationStack {
                ProjectsView()
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .environment(\.openStudioSheet, StudioSheetActions(
            enough: { showEnough = true },
            locations: { showLocations = true },
            projects: { showProjects = true },
            settings: { showSettings = true }
        ))
    }

    private func attemptAdd() {
        if FreeTier.canAddFabric(currentCount: fabrics.count, isUnlocked: purchases.isUnlocked) {
            showNewFabric = true
        } else {
            openEditorAfterUnlock = true
            showPaywall = true
        }
    }
}

struct StudioSheetActions {
    var enough: () -> Void
    var locations: () -> Void
    var projects: () -> Void
    var settings: () -> Void
}

private struct StudioSheetKey: EnvironmentKey {
    static let defaultValue = StudioSheetActions(enough: {}, locations: {}, projects: {}, settings: {})
}

extension EnvironmentValues {
    var openStudioSheet: StudioSheetActions {
        get { self[StudioSheetKey.self] }
        set { self[StudioSheetKey.self] = newValue }
    }
}

#Preview {
    RootView()
        .modelContainer(ModelStore.preview)
        .environment(PurchaseManager())
        .environment(UnitSettings())
}
