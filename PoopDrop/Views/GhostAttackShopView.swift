import SwiftUI
import StoreKit

struct GhostAttackShopView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var fartAttackManager: FartAttackManager
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("💩")
                            .font(.system(size: 60))
                        
                        Text("TheDailyPoop Shop")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Power-ups, attacks & reveals!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Current Inventory
                    if let inventory = fartAttackManager.inventory {
                        VStack(spacing: 12) {
                            Text("Your Inventory")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                InventoryCard(
                                    icon: "👻",
                                    title: "Ghost Attacks",
                                    count: inventory.availableAttacks
                                )
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // IAP Products Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Buy More")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Ghost Attack Pack
                        IAPProductCard(
                            icon: "👻",
                            title: "Ghost Attack Pack",
                            subtitle: "3 Anonymous Attacks",
                            features: [
                                "Send anonymous fart attacks",
                                "Friends have to guess who sent it",
                                "Hilarious reactions guaranteed"
                            ],
                            price: "$2.99",
                            productID: IAPProducts.ghostAttackPack3,
                            accent: .orange
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal)
                        
                        Text("Power-Ups")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // 2X Points Boost
                        IAPProductCard(
                            icon: "⚡️",
                            title: "2X Points Boost",
                            subtitle: "24 Hours",
                            features: [
                                "Double points for all actions",
                                "Climb the leaderboard faster",
                                "Active for 24 hours"
                            ],
                            price: "$1.99",
                            productID: IAPProducts.pointsBoost24h,
                            accent: .yellow
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal)
                        
                        Text("Reveals")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        // Ghost Reveal
                        IAPProductCard(
                            icon: "🔓",
                            title: "Reveal Ghost Sender",
                            subtitle: "One-Time Use",
                            features: [
                                "Instantly see who sent attack",
                                "No more guessing",
                                "Get your revenge!"
                            ],
                            price: "$0.99",
                            productID: IAPProducts.ghostHintReveal,
                            accent: .purple
                        )
                        
                        // Gossip Reveal (updated from Poll Reveal)
                        IAPProductCard(
                            icon: "☕",
                            title: "Reveal Gossip Sender",
                            subtitle: "One-Time Use",
                            features: [
                                "See who posted anonymous gossip",
                                "Know who's talking about you",
                                "Get your revenge!"
                            ],
                            price: "$1.99",
                            productID: IAPProducts.pollReveal,
                            accent: .red
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await storeKitManager.loadProducts()
            }
        }
    }
}

// MARK: - Inventory Card

struct InventoryCard: View {
    let icon: String
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 40))
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - IAP Product Card

struct IAPProductCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]
    let price: String
    let productID: String
    var accent: Color = .orange
    
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Icon
                Text(icon)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Price
                Text(price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(accent)
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accent)
                            .font(.caption)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Buy Button
            Button(action: {
                Task {
                    await purchaseProduct()
                }
            }) {
                Text("Buy Now - \(price)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func purchaseProduct() async {
        guard let product = storeKitManager.getProduct(byID: productID) else {
            print("❌ Product not loaded yet: \(productID)")
            return
        }
        
        do {
            let result = try await storeKitManager.purchase(product)
            print("✅ Purchase successful: \(product.id)")
        } catch {
            print("❌ Purchase failed: \(error)")
        }
    }
}

// MARK: - Preview

struct GhostAttackShopView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GhostAttackShopView()
                .environmentObject(AuthenticationManager())
                .environmentObject(FartAttackManager.shared)
        }
        .preferredColorScheme(.dark)
    }
}
