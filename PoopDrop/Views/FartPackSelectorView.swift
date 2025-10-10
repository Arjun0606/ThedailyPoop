import SwiftUI

struct FartPackSelectorView: View {
    @StateObject private var fartPackManager = FartPackManager.shared
    @Binding var selectedSound: FartSound?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPack: FartPack?
    @State private var showingShop = false
    
    init(selectedSound: Binding<FartSound?>) {
        self._selectedSound = selectedSound
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("💨")
                        .font(.system(size: 60))
                    
                    Text("Choose Your Fart")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select a sound to play when you drop")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Pack selector tabs
                if !fartPackManager.unlockedPacks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(fartPackManager.unlockedPacks) { pack in
                                PackTab(
                                    pack: pack,
                                    isSelected: selectedPack?.id == pack.id
                                )
                                .onTapGesture {
                                    withAnimation {
                                        selectedPack = pack
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                    .padding(.bottom, 8)
                }
                
                // Sounds grid
                ScrollView {
                    if let pack = selectedPack ?? fartPackManager.unlockedPacks.first {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(pack.sounds) { sound in
                                SoundButton(
                                    sound: sound,
                                    isSelected: selectedSound?.id == sound.id,
                                    onSelect: {
                                        selectedSound = sound
                                        fartPackManager.selectSound(sound)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // No packs unlocked
                        VStack(spacing: 16) {
                            Text("🔒")
                                .font(.system(size: 80))
                            
                            Text("No Fart Packs")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Visit the shop to unlock legendary fart sounds!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showingShop = true
                            }) {
                                Text("Browse Fart Packs")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.yellow)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    }
                }
                
                // Bottom bar
                HStack(spacing: 16) {
                    Button(action: {
                        showingShop = true
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Shop")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text(selectedSound == nil ? "Skip" : "Done")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.95))
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedPack = fartPackManager.unlockedPacks.first
            }
            .sheet(isPresented: $showingShop) {
                FartPackShopView()
            }
        }
    }
}

// MARK: - Pack Tab
struct PackTab: View {
    let pack: FartPack
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(pack.emoji)
                .font(.system(size: 30))
            
            Text(pack.name)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Sound Button
struct SoundButton: View {
    let sound: FartSound
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: {
            onSelect()
            isPlaying = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + sound.duration) {
                isPlaying = false
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    if isPlaying {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(isSelected ? .black : .white)
                            .font(.system(size: 24))
                    } else {
                        Image(systemName: "play.fill")
                            .foregroundColor(isSelected ? .black : .white)
                            .font(.system(size: 20))
                    }
                }
                
                VStack(spacing: 4) {
                    Text(sound.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(String(format: "%.1fs", sound.duration))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    FartPackSelectorView(selectedSound: .constant(nil))
}

