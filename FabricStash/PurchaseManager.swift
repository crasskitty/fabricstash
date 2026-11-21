import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    private(set) var isUnlocked = false
    private(set) var product: Product?
    private(set) var isBusy = false
    private(set) var lastMessage: String?

    @ObservationIgnored private var listening = false

    func start() async {
        if !listening {
            listening = true
            Task { [weak self] in
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    await self?.refreshEntitlements()
                }
            }
        }
        await refreshEntitlements()
        await loadProduct()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [AppIdentity.unlockProductID])
            product = products.first { $0.id == AppIdentity.unlockProductID }
            if product == nil {
                lastMessage = "The unlock is not available yet. In Xcode, set the scheme’s StoreKit configuration to Products.storekit. A released build loads it from App Store Connect."
            }
        } catch {
            lastMessage = "Could not load the unlock. \(error.localizedDescription)"
        }
    }

    /// `Transaction.currentEntitlements` is the source of truth, not a cached flag.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == AppIdentity.unlockProductID else { continue }
            if transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    lastMessage = isUnlocked ? "\(AppIdentity.displayName) is unlocked." : "The purchase finished, but the unlock is not active yet."
                case .unverified:
                    lastMessage = "The App Store could not verify that purchase."
                }
            case .userCancelled:
                break
            case .pending:
                lastMessage = "The purchase is pending approval."
            @unknown default:
                lastMessage = "The App Store returned an unexpected result."
            }
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastMessage = isUnlocked
                ? "\(AppIdentity.displayName) is unlocked on this Apple ID."
                : "No unlock was found for this Apple ID."
        } catch {
            lastMessage = "Could not reach the App Store. \(error.localizedDescription)"
        }
    }
}
