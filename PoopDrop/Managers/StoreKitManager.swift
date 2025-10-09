import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    // All fart attack pack product IDs
    private let fartAttackProductIDs = [
        "com.thedailypoop.fartattack.pack"
    ]
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Transaction Listener
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                // Update purchased products
                await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                
                // Fart attack pack purchased
                // Note: Inventory is updated in the UI layer where we have access to current user
                if transaction.productID == "com.thedailypoop.fartattack.pack" {
                    print("✅ Fart attack pack transaction verified")
                }
                    
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: fartAttackProductIDs)
            
            await MainActor.run {
                self.availableProducts = storeProducts.sorted { $0.price < $1.price }
                self.isLoading = false
            }
            
            // Check for existing purchases
            await updatePurchasedProducts()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("Error loading products: \(error)")
        }
    }
    
    // MARK: - Purchase Product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                
                // Fart attack pack purchased
                // Note: Inventory is updated in the UI layer where we have access to current user
                if transaction.productID == "com.thedailypoop.fartattack.pack" {
                    print("✅ Fart attack pack transaction verified")
                }
                
                await transaction.finish()
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.errorMessage = "Purchase is pending approval"
                    self.isLoading = false
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.errorMessage = "Purchase failed"
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Purchase error: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Update Purchased Products
    private func updatePurchasedProducts() async {
        // For consumable products (fart attacks), we don't use currentEntitlements
        // Inventory is tracked in FartAttackManager and CloudKit
        // This method is kept for potential future non-consumable products
        await MainActor.run {
            self.purchasedProductIDs = []
        }
    }
    
    // MARK: - Verification
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Methods
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    func getProduct(for productID: String) -> Product? {
        return availableProducts.first { $0.id == productID }
    }
    
    func getFartAttackProduct() -> Product? {
        return availableProducts.first { $0.id == "com.thedailypoop.fartattack.pack" }
    }
}

// MARK: - Store Errors
enum StoreKitError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}

// MARK: - Product Extensions
extension Product {
    var localizedPrice: String {
        return displayPrice
    }
}

