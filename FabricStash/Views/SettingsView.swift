import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchases
    @Environment(UnitSettings.self) private var units
    @Query private var fabrics: [Fabric]

    @State private var message: String?
    @State private var showPaywall = false

    private var sampleCount: Int { fabrics.filter(\.isSample).count }

    var body: some View {
        Form {
            Section {
                Picker("Units", selection: systemBinding) {
                    ForEach(MeasurementSystem.allCases) { system in
                        Text(system.title).tag(system)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Measurement units")
                Text(units.system.detail)
                    .foregroundStyle(Studio.inkSecondary)
            } header: {
                Text("Measurement")
            } footer: {
                Text("One choice sets both. Imperial is inches and yards, including fractions such as 1/2 and 44 1/2. Metric is centimeters and meters. Lengths stay stored in yards and widths in inches. 1 yard = 0.9144 m.")
            }

            Section {
                LabeledContent("Fabrics", value: "\(fabrics.count)")
                LabeledContent("Shelf", value: purchases.isUnlocked ? "Unlocked" : "Free, \(FreeTier.fabricLimit) fabrics")
                if !purchases.isUnlocked {
                    Button("Unlock unlimited fabrics") { showPaywall = true }
                }
                Button("Restore purchases") {
                    Task { await purchases.restore() }
                }
                .disabled(purchases.isBusy)
                if let last = purchases.lastMessage {
                    Text(last)
                        .font(.footnote)
                        .foregroundStyle(Studio.inkSecondary)
                }
            } header: {
                Text(AppIdentity.displayName)
            }

            Section {
                ShareLink(
                    item: CSVFile(text: CSVExport.render(rows: fabrics.map { $0.exportRow(system: units.system) }, system: units.system)),
                    preview: SharePreview(AppIdentity.csvFilename)
                ) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                NavigationLink("Locations") { LocationsView() }
                NavigationLink("Projects") { ProjectsView() }
                if sampleCount == 0 {
                    Button("Load sample fabrics", action: loadSamples)
                } else {
                    Button("Remove \(sampleCount) sample \(sampleCount == 1 ? "fabric" : "fabrics")", role: .destructive, action: removeSamples)
                }
            } header: {
                Text("On this device")
            } footer: {
                Text("Sample fabrics are fictional, labeled Sample, and safe to delete. They count toward the free shelf. Export writes a spreadsheet of what is stored here. Nothing is uploaded.")
            }

            Section {
                LabeledContent("Publisher", value: AppIdentity.publisher)
                LabeledContent("Version", value: version)
                Text("Kept on this device. No account, no analytics, and no iCloud sync in this version.")
                    .font(.footnote)
                    .foregroundStyle(Studio.inkSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .studioScreen()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Samples", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private var systemBinding: Binding<MeasurementSystem> {
        Binding(get: { units.system }, set: { units.system = $0 })
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func loadSamples() {
        do {
            try SampleFabrics.load(into: modelContext)
            message = "Sample fabrics are on the shelf. Their names start with Sample."
        } catch {
            message = error.localizedDescription
        }
    }

    private func removeSamples() {
        do {
            try SampleFabrics.remove(from: modelContext)
            message = "Sample fabrics were deleted."
        } catch {
            message = error.localizedDescription
        }
    }
}
