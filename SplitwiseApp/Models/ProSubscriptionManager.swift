import Foundation
import StoreKit

@Observable
public final class ProSubscriptionManager {
    public static let shared = ProSubscriptionManager()

    public static let monthlyProID = "app.billnest.pro.monthly"
    public static let yearlyProID = "app.billnest.pro.yearly"
    public static let allowedProProductIDs: Set<String> = [monthlyProID, yearlyProID]

    public var isPro: Bool = false
    public var products: [Product] = []
    public var purchasedIdentifiers: Set<String> = []
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    /// DEBUG-only override for local testing. Always false in Release builds.
    #if DEBUG
    public var isMockPro: Bool = false {
        didSet {
            updateProStatus()
        }
    }
    #else
    public var isMockPro: Bool {
        false
    }
    #endif

    private var transactionListener: Task<Void, Never>?

    private init() {
        updateProStatus()
        transactionListener = listenForTransactions()
        Task { @MainActor in
            await updatePurchasedIdentifiers()
            await fetchProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    @MainActor
    public func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = [Self.monthlyProID, Self.yearlyProID]
            self.products = try await Product.products(for: productIDs)
            self.errorMessage = nil
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
        case .userCancelled:
            errorMessage = nil
            return false
        case .pending:
            errorMessage = String(localized: "Purchase is pending approval.")
            return false
        @unknown default:
            return false
        }
    }

    @MainActor
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedIdentifiers()
            if !isPro {
                errorMessage = String(localized: "No active Pro subscription found.")
            } else {
                errorMessage = nil
            }
        } catch {
            errorMessage = String(localized: "Restore failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    public func updatePurchasedIdentifiers() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil,
                   Self.allowedProProductIDs.contains(transaction.productID) {
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
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
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
        #if DEBUG
        self.isPro = isMockPro || !purchasedIdentifiers.isEmpty
        #else
        self.isPro = !purchasedIdentifiers.isEmpty
        #endif
    }
}
