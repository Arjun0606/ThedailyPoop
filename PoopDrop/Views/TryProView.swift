import SwiftUI

struct TryProView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: ProFeature?
    @State private var isPurchasing = false
    
    private let proFeatures: [ProFeature] = [
        ProFeature(
            icon: "🌈",
            title: "Animated Poop Skins",
            description: "Rainbow, disco, gold, fire, ice & seasonal poops",
            freeVersion: "Static 💩",
            proVersion: "8+ animated skins"
        ),
        ProFeature(
            icon: "💬",
            title: "Extended Captions",
            description: "Express yourself with longer, detailed poop stories",
            freeVersion: "50 characters",
            proVersion: "200 words"
        ),
        ProFeature(
            icon: "😀",
            title: "All Emojis & Reactions",
            description: "React with any emoji, custom reaction packs",
            freeVersion: "4 basic emojis",
            proVersion: "All emojis + custom packs"
        ),
        ProFeature(
            icon: "🔥",
            title: "Animated Streaks",
            description: "Dynamic fire animations for your poop streaks",
            freeVersion: "Static 🔥",
            proVersion: "🔥🔥🔥 Animated flames"
        ),
        ProFeature(
            icon: "📍",
            title: "Extended Map Persistence",
            description: "Your poops stay visible longer on the map",
            freeVersion: "3 days",
            proVersion: "1 full month"
        ),
        ProFeature(
            icon: "🏆",
            title: "Achievement Badges",
            description: "Unlock exclusive geo-locked badges & achievements",
            freeVersion: "No badges",
            proVersion: "25+ unique badges"
        ),
        ProFeature(
            icon: "🔊",
            title: "Premium Sound Packs",
            description: "Custom fart, flush & plop sounds for notifications",
            freeVersion: "Basic poop sound",
            proVersion: "15+ premium sounds"
        ),
        ProFeature(
            icon: "🎨",
            title: "Custom Map Themes",
            description: "Beautiful map themes: Dark Luxury, Cosmic Galaxy",
            freeVersion: "Standard map",
            proVersion: "4 premium themes"
        ),
        ProFeature(
            icon: "👑",
            title: "Profile Flex Items",
            description: "Poop crown, golden toilet badge, highlighted name",
            freeVersion: "Basic profile",
            proVersion: "Premium profile items"
        ),
        ProFeature(
            icon: "🎁",
            title: "Monthly Exclusive Drops",
            description: "Special seasonal poop packs & limited editions",
            freeVersion: "Standard poops",
            proVersion: "Monthly exclusive content"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        ProHeaderView()
                        
                        // Feature List
                        LazyVStack(spacing: 16) {
                            ForEach(proFeatures) { feature in
                                ProFeatureCard(
                                    feature: feature,
                                    isSelected: selectedFeature?.id == feature.id
                                ) {
                                    selectedFeature = selectedFeature?.id == feature.id ? nil : feature
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Pricing
                        ProPricingCard()
                        
                        // Purchase Button
                        ProPurchaseButton(isPurchasing: $isPurchasing) {
                            startPurchase()
                        }
                        
                        // Free Features Reminder
                        FreeFeaturesList()
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Try Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func startPurchase() {
        isPurchasing = true
        
        Task {
            do {
                // Pro subscriptions removed - simplified ad-supported model
                // let success = try await subscriptionManager.purchaseProSubscription()
                let success = false // Always fail since no Pro version
                
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    // Show error alert
                }
            }
        }
    }
}

struct ProFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let freeVersion: String
    let proVersion: String
}

struct ProHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Animated crown
            Text("👑")
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: 8) {
                Text("Poop Drop Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Unlock the Ultimate Poop Experience")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Pro badge
            HStack {
                Text("PRO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(.top, 20)
    }
}

struct ProFeatureCard: View {
    let feature: ProFeature
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(feature.icon)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(feature.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                
                if isSelected {
                    VStack(spacing: 8) {
                        ComparisonRow(
                            title: "Free Version:",
                            value: feature.freeVersion,
                            color: .gray
                        )
                        
                        ComparisonRow(
                            title: "Pro Version:",
                            value: feature.proVersion,
                            color: .yellow
                        )
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

struct ComparisonRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct ProPricingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Unlock Everything")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("$6.99")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("/month")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Pricing options
                VStack(spacing: 8) {
                    PricingOptionRow(duration: "3 months", price: "$16.99", savings: "Save 19%")
                    PricingOptionRow(duration: "6 months", price: "$29.99", savings: "Save 28%")
                    PricingOptionRow(duration: "1 year", price: "$56.99", savings: "Save 32% + Best Value!", isRecommended: true)
                }
                .padding(.top, 8)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Cancel anytime")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("7-day free trial")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All future Pro features included")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .padding(.horizontal, 20)
    }
}

struct ProPurchaseButton: View {
    @Binding var isPurchasing: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.black)
                    Text("Processing...")
                } else {
                    Text("👑")
                        .font(.title3)
                    Text("Start Free Trial")
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
        .disabled(isPurchasing)
        .scaleEffect(isPurchasing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPurchasing)
    }
}

struct FreeFeaturesList: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Free Features (Always Available)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "👥", text: "Add unlimited friends")
                FeatureRow(icon: "💩", text: "Drop poops with location")
                FeatureRow(icon: "🔥", text: "Streak tracking")
                FeatureRow(icon: "😵‍💫", text: "'No Poop' streak protection")
                FeatureRow(icon: "📱", text: "Friend notifications")
                FeatureRow(icon: "🗺️", text: "Basic map view")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.body)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

struct PricingOptionRow: View {
    let duration: String
    let price: String
    let savings: String
    let isRecommended: Bool
    
    init(duration: String, price: String, savings: String, isRecommended: Bool = false) {
        self.duration = duration
        self.price = price
        self.savings = savings
        self.isRecommended = isRecommended
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(duration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(savings)
                    .font(.caption)
                    .foregroundColor(isRecommended ? .yellow : .green)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if isRecommended {
                    Text("👑")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isRecommended ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecommended ? Color.yellow.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TryProView()
        .environmentObject(SubscriptionManager())
}
