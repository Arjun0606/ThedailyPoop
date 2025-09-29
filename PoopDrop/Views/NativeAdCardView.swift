import SwiftUI
import UIKit

struct NativeAdCardView: View {
    let adViewModel: NativeAdViewModel
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sponsored tag
            AdHeaderView()
            
            // Main content
            AdContentView(adViewModel: adViewModel)
            
            // Call to action button
            AdCallToActionView(adViewModel: adViewModel, isPressed: $isPressed)
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Subviews
struct AdHeaderView: View {
    var body: some View {
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
            
            Image(systemName: "info.circle")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}

struct AdContentView: View {
    let adViewModel: NativeAdViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                )
            
            // Ad content
            VStack(alignment: .leading, spacing: 4) {
                if let headline = adViewModel.headline {
                    Text(headline)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                if let body = adViewModel.body {
                    Text(body)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                }
                
                // Rating and store info
                AdRatingView(adViewModel: adViewModel)
            }
            
            Spacer()
        }
    }
}

struct AdRatingView: View {
    let adViewModel: NativeAdViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            if let rating = adViewModel.starRating {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text(String(format: "%.1f", rating))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let store = adViewModel.store {
                Text("• \(store)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let price = adViewModel.price {
                Text("• \(price)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AdCallToActionView: View {
    let adViewModel: NativeAdViewModel
    @Binding var isPressed: Bool
    
    var body: some View {
        if let callToAction = adViewModel.callToAction {
            Button(action: {
                // Handle ad tap
                print("Ad tapped: \(adViewModel.headline ?? "Unknown")")
            }) {
                Text(callToAction)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            .pressEvents(
                onPress: { isPressed = true },
                onRelease: { isPressed = false }
            )
        }
    }
}

// MARK: - Button Press Events Extension
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - Google AdMob Integration (Placeholder)
// TODO: Add Google AdMob SDK and implement GoogleNativeAdView when ready for production

#Preview {
    NativeAdCardView(
        adViewModel: NativeAdViewModel(
            headline: "Taco Bell Volcano Burrito",
            body: "Get ready for the ultimate bathroom experience! 🌮🔥💩",
            callToAction: "Order Now",
            store: "Taco Bell",
            price: "$4.99"
        )
    )
    .padding()
    .background(Color.black)
}