import SwiftUI
import StoreKit

struct StreakFreezeBanner: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var storeKitManager: StoreKitManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var user: User? {
        authManager.currentUser
    }
    
    var timeRemaining: String {
        guard let user = user,
              let expiration = user.pendingStreakFreezeUntil else {
            return ""
        }
        
        let remaining = Int(expiration.timeIntervalSinceNow)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Expired"
        }
    }
    
    var body: some View {
        if let user = user, let expiration = user.pendingStreakFreezeUntil, expiration > Date() {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your streak broke!")
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                        
                        Text("Save your streak with a Streak Freeze")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("⏰ Time left: \(timeRemaining)")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray5))
                            )
                    }
                    
                    Button {
                        purchaseStreakFreeze()
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Restore Streak")
                                .font(.subheadline.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                    .disabled(isPurchasing)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            )
            .padding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchaseStreakFreeze() {
        guard let user = user else { return }
        
        isPurchasing = true
        
        Task {
            do {
                // Get the Streak Freeze product
                guard let product = await storeKitManager.getStreakFreezeProduct() else {
                    throw NSError(domain: "StreakFreeze", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not available"])
                }
                
                // Purchase it
                let success = try await storeKitManager.purchase(product)
                
                if success {
                    // Restore the streak
                    var updatedUser = user
                    updatedUser.pendingStreakFreezeUntil = nil
                    
                    try await cloudKitManager.saveUser(updatedUser)
                    
                    await MainActor.run {
                        authManager.currentUser = updatedUser
                        isPurchasing = false
                    }
                } else {
                    throw NSError(domain: "StreakFreeze", code: -2, userInfo: [NSLocalizedDescriptionKey: "Purchase failed"])
                }
            } catch {
                print("Error purchasing streak freeze: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }
    
    private func dismiss() {
        guard var user = user else { return }
        
        // Mark as dismissed (no longer pending)
        user.pendingStreakFreezeUntil = nil
        
        Task {
            do {
                try await cloudKitManager.saveUser(user)
                await MainActor.run {
                    authManager.currentUser = user
                }
            } catch {
                print("Error dismissing streak freeze: \(error)")
            }
        }
    }
}
