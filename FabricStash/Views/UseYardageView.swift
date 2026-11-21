import SwiftData
import SwiftUI
import UIKit

struct UseYardageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var units
    @Query(sort: \Project.name) private var projects: [Project]

    var fabric: Fabric

    @State private var amountText = ""
    @State private var choice: ProjectChoice = .new
    @State private var newProjectName = ""
    @State private var note = ""
    @State private var saveError: String?

    private enum ProjectChoice: Hashable {
        case new
        case existing(UUID)
    }

    private var plannedYards: Double? {
        units.yards(fromDisplay: amountText)
    }

    private var deduction: YardageDeduction? {
        guard let plannedYards else { return nil }
        return YardageLedger.deduct(remainingYards: fabric.yardage, amountYards: plannedYards)
    }

    private var projectReady: Bool {
        switch choice {
        case .new:
            return !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .existing:
            return true
        }
    }

    private var canSave: Bool {
        guard projectReady, case .applied = deduction else { return false }
        return true
    }

    var body: some View {
        Form {
            Section {
                Text("\(units.formatLength(yards: fabric.yardage)) on hand")
                    .foregroundStyle(Studio.ink)
                TextField("Amount to use (\(units.lengthUnit.abbreviation))", text: $amountText)
                    .keyboardType(.decimalPad)
                if let deduction {
                    switch deduction {
                    case .applied(let remaining):
                        Text("\(units.formatLength(yards: remaining)) would remain.")
                            .foregroundStyle(Studio.sewingGreen)
                    case .rejected(let reason):
                        Text(warning(reason))
                            .foregroundStyle(Studio.madder)
                    }
                } else if !amountText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Enter the amount as a number.")
                        .foregroundStyle(Studio.madder)
                }
            } header: {
                Text(fabric.name)
            } footer: {
                Text("A cut is refused if it would take the fabric below zero. Nothing is deducted until you save.")
            }

            Section("Project") {
                Picker("Project", selection: $choice) {
                    Text("New project").tag(ProjectChoice.new)
                    ForEach(projects) { project in
                        Text(project.name).tag(ProjectChoice.existing(project.id))
                    }
                }
                if case .new = choice {
                    TextField("Project name", text: $newProjectName)
                }
                TextField("Note", text: $note, prompt: Text("Optional, such as bodice"))
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Mark used")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Deduct", action: save)
                    .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
        .alert("Could not save the cut", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func warning(_ reason: YardageRejection) -> String {
        switch reason {
        case .amountMustBePositive:
            return "Enter an amount greater than zero."
        case .notANumber:
            return "That amount is not a number."
        case .wouldBeNegative(let shortfall):
            return "That would take it below zero. You are short by \(units.formatLength(yards: shortfall)). Nothing was deducted."
        }
    }

    private func save() {
        guard case .applied = deduction, let yards = plannedYards else { return }
        let project: Project
        switch choice {
        case .new:
            let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            project = Project(name: name)
            modelContext.insert(project)
        case .existing(let id):
            guard let existing = projects.first(where: { $0.id == id }) else {
                saveError = "That project is no longer here."
                return
            }
            project = existing
        }
        let fresh = YardageLedger.deduct(remainingYards: fabric.yardage, amountYards: yards)
        guard case .applied(let confirmed) = fresh else {
            saveError = "That cut no longer fits what is left."
            return
        }
        fabric.yardage = confirmed
        fabric.updatedAt = .now
        let use = YardageUse(
            yards: yards,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            fabric: fabric,
            project: project
        )
        modelContext.insert(use)
        dismiss()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
