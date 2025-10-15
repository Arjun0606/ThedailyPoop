import SwiftUI
import StoreKit

struct FartAttackShopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var fartAttackManager: FartAttackManager
    
    @State private var purchasing = false
    @State private var showSuccessAlert = false
    @State private var purchaseMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Info card
                        infoCard
                        
                        // Ghost Attack Packs
                        ghostAttacksSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("👻 Ghost Attack Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .alert("Purchase Complete!", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(purchaseMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("👻")
                .font(.system(size: 60))
            
            Text("Ghost Attack Shop")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("ALL attacks are anonymous!")
                .font(.subheadline)
                .foregroundColor(.purple)
            
            // Current inventory
            if let inventory = fartAttackManager.inventory {
                VStack(spacing: 4) {
                    Text("\(inventory.availableAttacks)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.purple)
                    Text("Attacks Available")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Info Card
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎮")
                    .font(.title)
                Text("How It Works")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "👻", text: "Send anonymous fart attack")
                InfoRow(icon: "❓", text: "They have 3 guesses to find you")
                InfoRow(icon: "🆓", text: "Free hint narrows to 3 people")
                InfoRow(icon: "💰", text: "$1.99 to reveal who sent it")
            }
        }
        .padding()
        .background(Color.purple.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Ghost Attacks
    
    private var ghostAttacksSection: some View {
        VStack(spacing: 16) {
            Text("💨 Ghost Attack Pack")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if let product3 = storeKitManager.getProduct(byID: IAPProducts.ghostAttackPack3) {
                // Single pack - prominent display
                VStack(spacing: 20) {
                    Text("👻")
                        .font(.system(size: 80))
                    
                    Text("3 Ghost Attacks")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(product3.displayPrice)
                        .font(.system(size: 50, weight: .black))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "👻", text: "100% Anonymous")
                        FeatureRow(icon: "🎮", text: "They guess who sent it")
                        FeatureRow(icon: "🆓", text: "Free hint (3 friends)")
                        FeatureRow(icon: "💰", text: "$0.99 to reveal sender")
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    Button(action: {
                        Task {
                            await purchaseProduct(product3, count: 3)
                        }
                    }) {
                        HStack {
                            if purchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "cart.fill")
                                    .font(.title3)
                                Text("Buy 3 Attacks")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .disabled(purchasing)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                )
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Purchase
    
    private func purchaseProduct(_ product: Product, count: Int) async {
        guard let user = authManager.currentUser else { return }
        purchasing = true
        
        do {
            let success = try await storeKitManager.purchase(product)
            
            if success {
                // Add attacks to inventory (all attacks are ghost now!)
                await fartAttackManager.addAttacksFromPurchase(for: user, count: count)
                
                purchaseMessage = "You got \(count) ghost attack\(count == 1 ? "" : "s")! Time to prank your friends 👻"
                showSuccessAlert = true
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        
        purchasing = false
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Attack Pack Card

struct AttackPackCard: View {
    let emoji: String
    let title: String
    let price: String
    let description: String
    var bestValue: Bool = false
    let onPurchase: () async -> Void
    
    @State private var isPurchasing = false
    
    var body: some View {
        Button(action: {
            Task {
                isPurchasing = true
                await onPurchase()
                isPurchasing = false
            }
        }) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if bestValue {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                if isPurchasing {
                    ProgressView()
                        .tint(.purple)
                } else {
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.5), lineWidth: 2)
            )
        }
        .padding(.horizontal)
        .disabled(isPurchasing)
    }
}

// MARK: - Preview

struct FartAttackShopView_Previews: PreviewProvider {
    static var previews: some View {
        FartAttackShopView()
            .environmentObject(StoreKitManager.shared)
            .environmentObject(AuthenticationManager())
            .preferredColorScheme(.dark)
    }
}
