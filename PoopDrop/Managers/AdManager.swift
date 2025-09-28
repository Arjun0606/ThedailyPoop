import Foundation
import GoogleMobileAds
import SwiftUI

// MARK: - Native Ad ViewModel
// A wrapper to make GADNativeAd easier to use in SwiftUI
struct NativeAdViewModel: Identifiable {
    let id = UUID()
    let nativeAd: GADNativeAd

    var headline: String? { nativeAd.headline }
    var body: String? { nativeAd.body }
    var callToAction: String? { nativeAd.callToAction }
    var icon: UIImage? { nativeAd.icon?.image }
    var starRating: Decimal? { nativeAd.starRating?.decimalValue }
    var store: String? { nativeAd.store }
    var price: String? { nativeAd.price }
    var advertiser: String? { nativeAd.advertiser }
    var mediaContent: GADMediaContent { nativeAd.mediaContent }
}

// MARK: - Ad Manager
@MainActor
class AdManager: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    static let shared = AdManager()

    @Published var nativeAd: NativeAdViewModel?
    private var adLoader: GADAdLoader?

    // Use Google's Test Ad Unit ID for Native Ads
    private let adUnitID = "ca-app-pub-3940256099942544/3986624511"
    
    override init() {
        super.init()
    }

    func loadAd() {
        guard adLoader == nil else {
            print("Ad loader is already active.")
            return
        }
        
        print("Loading new native ad...")
        adLoader = GADAdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }

    // MARK: - GADNativeAdLoaderDelegate Methods
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        print("✅ Native ad received successfully.")
        self.nativeAd = NativeAdViewModel(nativeAd: nativeAd)
        self.adLoader = nil // Reset loader for the next request
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Failed to receive native ad: \(error.localizedDescription)")
        self.adLoader = nil // Reset loader
    }
}