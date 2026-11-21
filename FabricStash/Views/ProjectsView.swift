import SwiftData
import SwiftUI

struct ProjectsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var units
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]

    @State private var name = ""
    @State private var pendingDelete: Project?

    var body: some View {
        List {
            Section {
                TextField("Project name", text: $name, prompt: Text("Linen trousers"))
                Button("Add project", action: add)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("You can also create a project while marking yardage used.")
            }

            if projects.isEmpty {
                Section {
                    Text("No projects yet. A project is where a cut gets written down.")
                        .foregroundStyle(Studio.inkSecondary)
                }
            }

            ForEach(projects) { project in
                Section {
                    if project.uses.isEmpty {
                        Text("No cuts yet.")
                            .foregroundStyle(Studio.inkSecondary)
                    } else {
                        ForEach(project.uses.sorted { $0.createdAt > $1.createdAt }) { use in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(use.fabric?.name ?? "Deleted fabric")
                                    .foregroundStyle(Studio.ink)
                                Text(units.formatLength(yards: use.yards))
                                    .font(.subheadline)
                                    .foregroundStyle(Studio.inkSecondary)
                                if !use.note.isEmpty {
                                    Text(use.note)
                                        .font(.subheadline)
                                        .foregroundStyle(Studio.ink)
                                }
                            }
                        }
                    }
                    Button("Delete project", role: .destructive) {
                        pendingDelete = project
                    }
                } header: {
                    Text("\(project.name) · \(units.formatLength(yards: project.totalYards))")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog(
            "Delete this project?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete and restore yardage", role: .destructive) {
                if let pendingDelete { delete(pendingDelete) }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Every cut on this project is put back on its fabric.")
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(Project(name: trimmed))
        name = ""
    }

    private func delete(_ project: Project) {
        for use in project.uses {
            if let fabric = use.fabric {
                fabric.yardage = YardageLedger.restore(remainingYards: fabric.yardage, usedYards: use.yards)
                fabric.updatedAt = .now
            }
        }
        modelContext.delete(project)
    }
}
