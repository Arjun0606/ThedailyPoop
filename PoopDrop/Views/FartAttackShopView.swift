import SwiftUI
import StoreKit

struct FartAttackShopView: View {
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var purchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var attacksAvailable: Int {
        fartAttackManager.inventory?.availableAttacks ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    // Top bar with title
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("💨 Fart Attacks")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.white)
                                
                                if attacksAvailable > 0 {
                                    Text("\(attacksAvailable) ready to send")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Get your first pack")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    
                    
                    VStack(spacing: 24) {
                        // Current Inventory - PROMINENT
                        if attacksAvailable > 0 {
                            VStack(spacing: 16) {
                                Text("YOUR ARSENAL")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .tracking(2)
                                
                                HStack(spacing: 12) {
                                    Text("💨")
                                        .font(.system(size: 60))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(attacksAvailable)")
                                            .font(.system(size: 48, weight: .black))
                                            .foregroundColor(.yellow)
                                        
                                        Text("Attacks Ready")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                                )
                                
                                Button(action: {
                                    // Navigate to Friends tab
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send to Friends")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                        } else {
                            // No attacks - show promo
                            VStack(spacing: 12) {
                                Text("💨")
                                    .font(.system(size: 100))
                                
                                Text("Fart Attack Pack")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Prank your friends with legendary farts")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                        }
                        
                        // Single Product Card
                        if let product = storeKitManager.getFartAttackProduct() {
                            VStack(spacing: 0) {
                                VStack(spacing: 16) {
                                    Text("💨")
                                        .font(.system(size: 80))
                                    
                                    Text("\(FartAttackPack.attacksPerPack) Fart Attacks")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text(product.displayPrice)
                                        .font(.system(size: 40, weight: .black))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.vertical, 24)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    FeatureRow(icon: "💨", text: "Send \(FartAttackPack.attacksPerPack) legendary fart attacks")
                                    FeatureRow(icon: "🎵", text: "4 seconds of epic audio")
                                    FeatureRow(icon: "⚡", text: "Instant delivery to friends")
                                    FeatureRow(icon: "🤣", text: "Plays when they open app")
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .background(Color.white.opacity(0.05))
                            }
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                            )
                            .padding(.horizontal)
                            
                            Button(action: {
                                purchase()
                            }) {
                                HStack(spacing: 12) {
                                    if purchasing {
                                        ProgressView()
                                            .tint(.black)
                                    } else {
                                        Image(systemName: "cart.fill")
                                            .font(.title3)
                                        Text("Buy \(FartAttackPack.attacksPerPack) Attacks for \(product.displayPrice)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(16)
                            }
                            .disabled(purchasing || storeKitManager.isLoading)
                            .padding(.horizontal)
                        } else {
                            // Loading products
                            ProgressView("Loading...")
                                .tint(.white)
                                .padding()
                        }
                        
                        // Info text
                        VStack(spacing: 8) {
                            Text("• Consumable purchase - buy as many as you want")
                            Text("• Each attack costs $0.66")
                            Text("• 24 hour cooldown per friend")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Purchase Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchase() {
        guard let product = storeKitManager.getFartAttackProduct() else {
            errorMessage = "Product not available"
            showingError = true
            return
        }
        
        purchasing = true
        
        Task {
            do {
                let success = try await storeKitManager.purchase(product)
                
                if success, let currentUser = authManager.currentUser {
                    // Add attacks to inventory after successful purchase
                    await fartAttackManager.addAttacksFromPurchase(for: currentUser, count: FartAttackPack.attacksPerPack)
                }
                
                await MainActor.run {
                    purchasing = false
                    
                    if success {
                        // Success is shown by updated inventory count
                        // Optionally dismiss after purchase
                        // dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    showingError = true
                    purchasing = false
                }
            }
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
                .font(.title2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    FartAttackShopView()
}

