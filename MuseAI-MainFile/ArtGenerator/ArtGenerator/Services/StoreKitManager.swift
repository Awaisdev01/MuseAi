import StoreKit
import SwiftUI

enum SubscriptionTier: String, CaseIterable {
    case monthly = "com.artgenerator.monthly"
    case yearly = "com.artgenerator.yearly"
    case lifetime = "com.artgenerator.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var description: String {
        switch self {
        case .monthly: return "$3.99/month"
        case .yearly: return "$9.99/year"
        case .lifetime: return "$19.99 once"
        }
    }

    var badge: String? {
        switch self {
        case .yearly: return "Best Value"
        case .lifetime: return "Most Popular"
        default: return nil
        }
    }
}

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }

    private var updateListenerTask: Task<Void, Error>?
    private let productIDs = SubscriptionTier.allCases.map(\.rawValue)

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
                .sorted { ($0.price as NSDecimalNumber).doubleValue < ($1.price as NSDecimalNumber).doubleValue }
        } catch {
            errorMessage = "Failed to load products."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        try? await AppStore.sync()
        await updatePurchasedProducts()

        if purchasedProductIDs.isEmpty {
            errorMessage = "No purchases to restore."
        }
    }

    func product(for tier: SubscriptionTier) -> Product? {
        products.first { $0.id == tier.rawValue }
    }

    private func updatePurchasedProducts() async {
        var purchased = Set<String>()

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification

        var errorDescription: String? {
            "Purchase verification failed."
        }
    }
}
