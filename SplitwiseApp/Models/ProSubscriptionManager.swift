import Foundation
import StoreKit

@Observable
public final class ProSubscriptionManager {
    public static let shared = ProSubscriptionManager()

    public static let monthlyProID = "com.splitwise.pro.monthly"
    public static let yearlyProID = "com.splitwise.pro.yearly"

    public var isPro: Bool = false
    public var products: [Product] = []
    public var purchasedIdentifiers: Set<String> = []
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // Sandbox / Mock override for immediate testing without active App Store Connect Sandbox setup
    public var isMockPro: Bool = true {
        didSet {
            updateProStatus()
        }
    }

    private init() {
        updateProStatus()
        Task {
            await fetchProducts()
            await listenForTransactions()
        }
    }

    @MainActor
    public func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = [Self.monthlyProID, Self.yearlyProID]
            self.products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to fetch StoreKit 2 products: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedIdentifiers()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    @MainActor
    public func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedIdentifiers()
    }

    @MainActor
    public func updatePurchasedIdentifiers() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error.localizedDescription)")
            }
        }
        self.purchasedIdentifiers = purchased
        updateProStatus()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedIdentifiers()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    public func updateProStatus() {
        self.isPro = isMockPro || !purchasedIdentifiers.isEmpty
    }
}
