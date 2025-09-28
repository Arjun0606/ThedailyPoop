import SwiftUI
import GoogleMobileAds

struct NativeAdCardView: View {
    let adViewModel: NativeAdViewModel
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sponsored tag
            HStack {
                Text("Sponsored")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                if let advertiser = adViewModel.advertiser {
                    Text(advertiser)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Ad content
            HStack(alignment: .top, spacing: 12) {
                // App icon (if available)
                if let icon = adViewModel.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } else {
                    // Placeholder for missing icon
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "app.fill")
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                
                // Ad text content
                VStack(alignment: .leading, spacing: 6) {
                    // Headline
                    if let headline = adViewModel.headline {
                        Text(headline)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    // Body text
                    if let body = adViewModel.body {
                        Text(body)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                    }
                    
                    // Store and price info
                    HStack {
                        if let store = adViewModel.store {
                            Text(store)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        if let price = adViewModel.price, !price.isEmpty {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text(price)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        // Star rating
                        if let rating = adViewModel.starRating, rating.doubleValue > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { index in
                                    Image(systemName: index < Int(rating.doubleValue) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Call to action button
            if let callToAction = adViewModel.callToAction {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Handle ad tap - Google will handle the navigation
                        handleAdTap()
                    }) {
                        Text(callToAction)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        isPressed = pressing
                    }, perform: {})
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
    
    private func handleAdTap() {
        // Google's SDK will automatically handle the tap and navigation
        // We just need to trigger the native ad's built-in tap handling
        print("📱 Ad tapped: \(adViewModel.headline ?? "Unknown ad")")
    }
}

// MARK: - UIViewRepresentable for Native Ad
// This bridges the GADNativeAd to SwiftUI properly
struct GoogleNativeAdView: UIViewRepresentable {
    let nativeAd: GADNativeAd
    
    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.nativeAd = nativeAd
        return adView
    }
    
    func updateUIView(_ uiView: GADNativeAdView, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#Preview {
    // Mock data for preview
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Text("Example of how native ads look in the feed:")
                .foregroundColor(.white)
                .padding()
            
            // Mock ad card (for preview only)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sponsored")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("Example App Store")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("📱")
                                .font(.title2)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amazing Productivity App")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Boost your productivity with this amazing app that helps you get things done faster.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(3)
                        
                        HStack {
                            Text("App Store")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text("Free")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { index in
                                    Image(systemName: index < 4 ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Get")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}
