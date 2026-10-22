import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let removeAdsProductID = "lt.bourdo.noiseradar.remove_ads"
    static let removeAdsFallbackPrice = "€0.99"
    private static let adFreeStorageKey = "isAdFree"

    @Published private(set) var removeAdsProduct: Product?
    @Published private(set) var isAdFree: Bool
    @Published private(set) var purchaseStatusMessage = ""
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        isAdFree = UserDefaults.standard.bool(forKey: Self.adFreeStorageKey)
        transactionUpdatesTask = listenForTransactionUpdates()

        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: [Self.removeAdsProductID])
            removeAdsProduct = products.first
        } catch {
            purchaseStatusMessage = "Purchase unavailable"
        }
    }

    func purchaseRemoveAds() async {
        if isAdFree {
            purchaseStatusMessage = "Already purchased"
            return
        }

        guard let product = removeAdsProduct else {
            purchaseStatusMessage = "Purchase unavailable"
            await loadProducts()
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await grantAdFreeAccess()
                await transaction.finish()
                purchaseStatusMessage = "Ads removed"
            case .pending:
                purchaseStatusMessage = "Purchase pending"
            case .userCancelled:
                purchaseStatusMessage = ""
            @unknown default:
                purchaseStatusMessage = "Purchase unavailable"
            }
        } catch {
            purchaseStatusMessage = "Purchase failed"
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseStatusMessage = isAdFree ? "Purchase restored" : "No purchase found"
        } catch {
            purchaseStatusMessage = "Restore failed"
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.productID == Self.removeAdsProductID else {
                continue
            }

            await grantAdFreeAccess()
            return
        }
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                guard let transaction = try? checkVerified(result),
                      transaction.productID == Self.removeAdsProductID else {
                    continue
                }

                await grantAdFreeAccess()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreKitError.notAvailableInStorefront
        }
    }

    private func grantAdFreeAccess() async {
        isAdFree = true
        UserDefaults.standard.set(true, forKey: Self.adFreeStorageKey)
    }
}
