import SwiftData
import SwiftUI

struct LocationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]

    @State private var name = ""
    @State private var kind: StorageKind = .bin
    @State private var pendingDelete: StorageLocation?

    var body: some View {
        List {
            Section {
                TextField("Name", text: $name, prompt: Text("Cedar bin, hall closet"))
                Picker("Kind", selection: $kind) {
                    ForEach(StorageKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                Button("Add location", action: add)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("New place")
            } footer: {
                Text("A bin, shelf, or room. Deleting a place keeps the fabrics. They just lose the label.")
            }

            Section("Places") {
                if locations.isEmpty {
                    Text("No locations yet.")
                        .foregroundStyle(Studio.inkSecondary)
                }
                ForEach(locations) { location in
                    NavigationLink {
                        LocationEditor(location: location)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .foregroundStyle(Studio.ink)
                            Text("\(location.kind.title) · \(location.fabrics.count) \(location.fabrics.count == 1 ? "fabric" : "fabrics")")
                                .font(.subheadline)
                                .foregroundStyle(Studio.inkSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            pendingDelete = location
                        }
                    }
                }
                .onMove(perform: move)
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .confirmationDialog(
            "Remove this location?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove location", role: .destructive) {
                if let pendingDelete {
                    modelContext.delete(pendingDelete)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Fabrics stay in \(AppIdentity.displayName). They will show as having no location.")
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let order = (locations.map(\.sortOrder).max() ?? -1) + 1
        let location = StorageLocation(name: trimmed, kind: kind, sortOrder: order)
        modelContext.insert(location)
        name = ""
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = locations
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, location) in ordered.enumerated() {
            location.sortOrder = index
        }
    }
}

private struct LocationEditor: View {
    @Bindable var location: StorageLocation

    var body: some View {
        Form {
            TextField("Name", text: $location.name)
            Picker("Kind", selection: kindBinding) {
                ForEach(StorageKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Edit location")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var kindBinding: Binding<StorageKind> {
        Binding(get: { location.kind }, set: { location.kind = $0 })
    }
}
