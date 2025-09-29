import SwiftUI
import UIKit

// Mock Banner Ad View (Ready for GoogleMobileAds)
struct MapBannerAdView: View {
    @StateObject private var adManager = AdManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // TODO: Replace with GADBannerView when SDK added
            // GADBannerView(adUnitID: AdMobConfig.mapBannerAdUnitID)
            
            // Mock banner for testing
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Sponsored Location")
                    .font(.caption)
                Spacer()
                Text("AD")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .onTapGesture {
                adManager.trackBannerImpression()
            }
        }
        .frame(height: 32)
        .onAppear {
            adManager.trackBannerImpression()
        }
    }
}

// Preview
struct MapBannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        MapBannerAdView()
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .previewLayout(.fixed(width: 320, height: 50))
    }
}