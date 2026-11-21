import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("The free shelf holds \(FreeTier.fabricLimit)")
                        .font(Studio.serif(.largeTitle, weight: .semibold))
                        .foregroundStyle(Studio.ink)
                    Text("Unlock \(AppIdentity.displayName) once to keep every bolt, scrap, and remnant on this device. Fabrics you already have can still be edited, photographed, and cut while the shelf is full.")
                        .foregroundStyle(Studio.ink)
                    Text("Deleting a fabric frees a spot. The limit is how many you can store, not how many you have ever added. The price is the one-time price from the App Store.")
                        .foregroundStyle(Studio.ink)
                    if let product = purchases.product {
                        Text(product.displayPrice)
                            .font(Studio.serif(.title, weight: .semibold))
                            .foregroundStyle(Studio.madder)
                            .accessibilityLabel("Price \(product.displayPrice)")
                        Button(purchases.isBusy ? "Working…" : "Unlock for \(product.displayPrice)") {
                            Task { await purchases.purchase() }
                        }
                        .buttonStyle(MadderButtonStyle())
                        .disabled(purchases.isBusy)
                    } else {
                        Text("The App Store price appears here when the unlock product loads.")
                            .foregroundStyle(Studio.inkSecondary)
                        Button("Try loading it again") {
                            Task { await purchases.loadProduct() }
                        }
                        .buttonStyle(MadderButtonStyle())
                    }
                    Button(purchases.isBusy ? "Working…" : "Restore purchases") {
                        Task { await purchases.restore() }
                    }
                    .buttonStyle(GreenButtonStyle())
                    .disabled(purchases.isBusy)
                    if let message = purchases.lastMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(Studio.inkSecondary)
                    }
                    if purchases.isUnlocked {
                        Text("This Apple ID already has the unlock.")
                            .foregroundStyle(Studio.sewingGreen)
                        Button("Continue") { dismiss() }
                            .buttonStyle(MadderButtonStyle())
                    }
                    Button("Not now") { dismiss() }
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
            .studioScreen()
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: purchases.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }
}
