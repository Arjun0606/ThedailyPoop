import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isProSubscriber = false
    @Published var subscriptionStatus: Product.SubscriptionInfo.Status?
    @Published var availableProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productIds = ["com.poopdrop.pro.monthly"]
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    @discardableResult
    func requestProducts() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            
            await MainActor.run {
                self.availableProducts = storeProducts
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return transaction
            
        case .userCancelled, .pending:
            await MainActor.run {
                self.isLoading = false
            }
            return nil
            
        default:
            await MainActor.run {
                self.errorMessage = "Purchase failed"
                self.isLoading = false
            }
            return nil
        }
    }
    
    func checkSubscriptionStatus() async {
        await updateCustomerProductStatus()
    }
    
    func updateCustomerProductStatus() async {
        var purchasedProducts: [Product] = []
        var isProSubscriber = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    purchasedProducts.append(product)
                    
                    // Check if this is the Pro subscription
                    if transaction.productID == "com.poopdrop.pro.monthly" {
                        isProSubscriber = true
                    }
                }
            } catch {
                print("Failed to verify transaction")
            }
        }
        
        await MainActor.run {
            self.purchasedProducts = purchasedProducts
            self.isProSubscriber = isProSubscriber
        }
        
        // Update user's Pro status in CloudKit
        // Pro features removed - simplified ad-supported model
        // if let currentUser = await AuthenticationManager().currentUser {
        //     var updatedUser = currentUser
        //     updatedUser.isPro = isProSubscriber
        //     
        //     do {
        //         try await CloudKitManager.shared.saveUser(updatedUser)
        //     } catch {
        //         print("Failed to update user Pro status: \(error)")
        //     }
        // }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        try? await AppStore.sync()
        await updateCustomerProductStatus()
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}

// MARK: - Product Extensions
extension Product {
    var displayPrice: String {
        return self.displayName
    }
    
    var localizedTitle: String {
        switch id {
        case "com.poopdrop.pro.monthly":
            return "Poop Drop Pro"
        default:
            return displayName
        }
    }
    
    var localizedDescription: String {
        switch id {
        case "com.poopdrop.pro.monthly":
            return "Unlock premium features: 200-word captions, all emojis, custom skins, animations, sounds, and exclusive map themes!"
        default:
            return description
        }
    }
}
