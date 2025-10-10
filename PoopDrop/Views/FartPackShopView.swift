import SwiftUI
import StoreKit

struct FartPackShopView: View {
    @StateObject private var fartPackManager = FartPackManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPack: FartPack?
    @State private var showingPurchaseConfirmation = false
    @State private var showingRestoreAlert = false
    @State private var purchaseInProgress = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("💨")
                            .font(.system(size: 80))
                        
                        Text("Fart Pack Shop")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock legendary fart sounds")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Unlocked Packs Section
                    if !fartPackManager.unlockedPacks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR COLLECTION")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ForEach(fartPackManager.unlockedPacks) { pack in
                                FartPackCard(pack: pack, isUnlocked: true)
                                    .onTapGesture {
                                        selectedPack = pack
                                    }
                            }
                        }
                    }
                    
                    // Available for Purchase Section
                    if !fartPackManager.lockedPacks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AVAILABLE PACKS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ForEach(fartPackManager.lockedPacks) { pack in
                                FartPackCard(pack: pack, isUnlocked: false)
                                    .onTapGesture {
                                        selectedPack = pack
                                        showingPurchaseConfirmation = true
                                    }
                            }
                        }
                    }
                    
                    // Restore Purchases Button
                    Button(action: {
                        Task {
                            await fartPackManager.restorePurchases()
                            showingRestoreAlert = true
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPack) { pack in
                FartPackDetailView(pack: pack, isUnlocked: fartPackManager.isPackUnlocked(pack))
            }
            .alert("Restore Complete", isPresented: $showingRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your purchases have been restored.")
            }
            .overlay {
                if storeKitManager.isLoading || fartPackManager.isLoading {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Fart Pack Card
struct FartPackCard: View {
    let pack: FartPack
    let isUnlocked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section with emoji and badge
            HStack {
                Text(pack.emoji)
                    .font(.system(size: 50))
                
                Spacer()
                
                if isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("OWNED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("$\(String(format: "%.2f", pack.price))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            
            // Pack info
            VStack(alignment: .leading, spacing: 8) {
                Text(pack.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(pack.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Sound count
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                    Text("\(pack.sounds.count) sound\(pack.sounds.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .padding(.top, 4)
            }
            .padding([.horizontal, .bottom])
            
            if !isUnlocked {
                // Purchase button
                HStack {
                    Spacer()
                    Text("TAP TO PURCHASE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.yellow.opacity(0.15))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Fart Pack Detail View
struct FartPackDetailView: View {
    let pack: FartPack
    let isUnlocked: Bool
    
    @StateObject private var fartPackManager = FartPackManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseInProgress = false
    @State private var showingPurchaseError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pack Header
                    VStack(spacing: 12) {
                        Text(pack.emoji)
                            .font(.system(size: 100))
                        
                        Text(pack.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(pack.description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Sounds List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("INCLUDED SOUNDS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        ForEach(pack.sounds) { sound in
                            SoundRow(sound: sound, isUnlocked: isUnlocked)
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Purchase/Info Button
                    if isUnlocked {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Pack Owned")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(12)
                            
                            Text("Use these sounds when creating drops!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    purchaseInProgress = true
                                    let success = await fartPackManager.purchasePack(pack)
                                    purchaseInProgress = false
                                    
                                    if success {
                                        dismiss()
                                    } else {
                                        errorMessage = "Purchase failed. Please try again."
                                        showingPurchaseError = true
                                    }
                                }
                            }) {
                                HStack {
                                    if purchaseInProgress {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "cart.fill")
                                        Text("Purchase for $\(String(format: "%.2f", pack.price))")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .disabled(purchaseInProgress)
                            
                            Text("One-time purchase • Unlock forever")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Failed", isPresented: $showingPurchaseError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Sound Row
struct SoundRow: View {
    let sound: FartSound
    let isUnlocked: Bool
    
    @StateObject private var fartPackManager = FartPackManager.shared
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                isPlaying = true
                fartPackManager.playSound(sound)
                
                // Reset playing state after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + sound.duration) {
                    isPlaying = false
                }
            }
        }) {
            HStack(spacing: 12) {
                // Play button
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.yellow : Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isPlaying ? "speaker.wave.3.fill" : "play.fill")
                        .foregroundColor(isPlaying ? .black : .white)
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(sound.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .disabled(!isUnlocked)
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    FartPackShopView()
}

