import SwiftUI

struct FartAttackPromoCard: View {
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @State private var showingShop = false
    @State private var isDismissed = false
    
    var attacksAvailable: Int {
        fartAttackManager.inventory?.availableAttacks ?? 0
    }
    
    var body: some View {
        if !isDismissed {
            VStack(spacing: 0) {
                // Header with NEW badge
                HStack {
                    HStack(spacing: 8) {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(4)
                        
                        Text("💨 Ghost Attacks")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isDismissed = true
                            UserDefaults.standard.set(true, forKey: "hasDismissedFartAttackPromo")
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                
                // Main content
                if attacksAvailable > 0 {
                    // Has attacks - encourage use
                    VStack(spacing: 16) {
                        Text("🎉")
                            .font(.system(size: 60))
                        
                        Text("You have \(attacksAvailable) Ghost Attack\(attacksAvailable == 1 ? "" : "s")!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Go prank your friends!\nThey'll never see it coming 💨")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // This would switch to Friends tab
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
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                } else {
                    // No attacks - promote purchase
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Text("💨")
                                .font(.system(size: 70))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Prank Your Friends!")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Send legendary ghost attacks\n1st attack FREE! 🎁")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            showingShop = true
                        }) {
                            HStack(spacing: 8) {
                                Text("🎁")
                                Text("Get Your Free Attack")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.5), lineWidth: 2)
            )
            .padding(.horizontal)
            .sheet(isPresented: $showingShop) {
                FartAttackShopView()
            }
        }
    }
}

#Preview {
    FartAttackPromoCard()
        .preferredColorScheme(.dark)
}

