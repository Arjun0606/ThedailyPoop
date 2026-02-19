import Foundation
import RevenueCat

// MARK: - Subscription Manager
// Wraps RevenueCat SDK. Single source of truth for premium status.
//
// Setup required in RevenueCat dashboard:
// 1. Create project with bundle ID: com.thedailypoop.app
// 2. Create entitlement: "premium"
// 3. Create products:
//    - tdp_monthly ($7.99/mo)
//    - tdp_annual ($59.99/yr)
// 4. Create offering "default" with both products
// 5. Set API key in configure() below

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isPremium = false
    @Published var isLoading = false

    private static let apiKey = "appl_xaQHfcpaycQoenMwgCIeJRYiTFp"

    private static let entitlementID = "premium"
    static let monthlyProductID = "tdp_monthly"
    static let annualProductID = "tdp_annual"

    private static var isConfigured = false

    // MARK: - Configure

    /// Call once at app launch (in PoopDropApp.init or .onAppear)
    func configure() {
        guard Self.apiKey != "YOUR_REVENUECAT_API_KEY" else {
            print("RevenueCat: Skipping configuration (no API key set)")
            return
        }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        Self.isConfigured = true
    }

    /// Login the RevenueCat user after Supabase auth completes
    func login(userID: String) async {
        guard Self.isConfigured else { return }
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userID)
            updatePremiumStatus(from: customerInfo)
        } catch {
            print("RevenueCat login error: \(error)")
        }
    }

    /// Logout when user signs out
    func logout() async {
        isPremium = false
        guard Self.isConfigured else { return }
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            print("RevenueCat logout error: \(error)")
        }
    }

    // MARK: - Check Status

    /// Refresh entitlement status from RevenueCat
    func checkSubscriptionStatus() async {
        guard Self.isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremiumStatus(from: customerInfo)
        } catch {
            print("RevenueCat status check error: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a package (monthly or annual)
    func purchase(productID: String) async -> Bool {
        guard Self.isConfigured else { return false }
        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else {
                print("No current offering found")
                return false
            }

            guard let package = offering.availablePackages.first(where: {
                $0.storeProduct.productIdentifier == productID
            }) else {
                print("Product \(productID) not found in offering")
                return false
            }

            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                updatePremiumStatus(from: result.customerInfo)
                return isPremium
            }
            return false
        } catch {
            print("Purchase error: \(error)")
            return false
        }
    }

    // MARK: - Restore

    /// Restore purchases (required by App Store guidelines)
    func restorePurchases() async -> Bool {
        guard Self.isConfigured else { return false }
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updatePremiumStatus(from: customerInfo)
            return isPremium
        } catch {
            print("Restore error: \(error)")
            return false
        }
    }

    // MARK: - Private

    private func updatePremiumStatus(from customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements[Self.entitlementID]?.isActive == true
    }
}
