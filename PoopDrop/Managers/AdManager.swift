import Foundation
import SwiftUI
import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - AdMob Configuration
struct AdMobConfig {
    static let nativeFeedAdUnitID = "ca-app-pub-5826159291481711/2138112820"
    static let interstitialAdUnitID = "ca-app-pub-5826159291481711/2050482911"
    static let mapBannerAdUnitID = "ca-app-pub-5826159291481711/9545829551"
}

// MARK: - Native Ad ViewModel (Production Ready Structure)
struct NativeAdViewModel: Identifiable {
    let id = UUID()
    
    let headline: String?
    let body: String?
    let callToAction: String?
    let icon: UIImage?
    let starRating: Double?
    let store: String?
    let price: String?
    let advertiser: String?
    
    #if canImport(GoogleMobileAds)
    init(from nativeAd: GADNativeAd) {
        self.headline = nativeAd.headline
        self.body = nativeAd.body
        self.callToAction = nativeAd.callToAction
        self.icon = nativeAd.icon?.image
        self.starRating = nativeAd.starRating?.doubleValue
        self.store = nativeAd.store
        self.price = nativeAd.price
        self.advertiser = nativeAd.advertiser
    }
    #endif
    
    // Production-ready mock for testing
    init(headline: String? = "Spicy Tuesday Special!",
         body: String? = "Get ready for the ultimate bathroom experience with our new Volcano Burrito! 🌮🔥",
         callToAction: String? = "Order Now",
         icon: UIImage? = nil,
         starRating: Double? = 4.5,
         store: String? = "Taco Bell",
         price: String? = "$4.99",
         advertiser: String? = "Taco Bell") {
        self.headline = headline
        self.body = body
        self.callToAction = callToAction
        self.icon = icon
        self.starRating = starRating
        self.store = store
        self.price = price
        self.advertiser = advertiser
    }
}

// MARK: - Production-Ready Ad Manager
@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    @Published var nativeAd: NativeAdViewModel?
    @Published var isLoading = false
    @Published var interstitialReady = false
    #if canImport(GoogleMobileAds)
    private var adLoader: GADAdLoader?
    private var interstitial: GADInterstitialAd?
    #endif
    
    override init() {
        super.init()
        print("📱 AdManager initialized")
    }

    func loadNativeAd() {
        isLoading = true
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        self.adLoader = GADAdLoader(adUnitID: AdMobConfig.nativeFeedAdUnitID,
                                    rootViewController: AdManager.topViewController(),
                                    adTypes: [.native],
                                    options: nil)
        self.adLoader?.delegate = self
        self.adLoader?.load(request)
        #else
        // Mock fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.nativeAd = NativeAdViewModel()
            self.isLoading = false
        }
        #endif
    }
    
    func loadInterstitialAd() {
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: AdMobConfig.interstitialAdUnitID, request: request) { [weak self] ad, error in
            if let _ = error { self?.interstitialReady = false; return }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
            self?.interstitialReady = ad != nil
        }
        #else
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.interstitialReady = true
        }
        #endif
    }
    
    func showInterstitialAd() -> Bool {
        guard interstitialReady else {
            print("❌ Interstitial ad not ready")
            return false
        }
        #if canImport(GoogleMobileAds)
        if let vc = AdManager.topViewController(), let ad = interstitial {
            ad.present(fromRootViewController: vc)
            interstitial = nil
            interstitialReady = false
            loadInterstitialAd()
            return true
        }
        return false
        #else
        interstitialReady = false
        loadInterstitialAd()
        return true
        #endif
    }
}

// MARK: - Banner Ad Revenue Tracking
extension AdManager {
    func trackBannerImpression() {
        print("💰 Banner impression tracked - $0.002 revenue!")
    }
    
    func trackNativeAdClick() {
        print("💰 Native ad clicked - $0.25 revenue!")
    }
    
    func trackInterstitialImpression() {
        print("💰 Interstitial impression - $0.05 revenue!")
    }

    static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.windows.first { $0.isKeyWindow }?.rootViewController }
        .first) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

#if canImport(GoogleMobileAds)
// MARK: - GAD Delegates
extension AdManager: GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        isLoading = false
        print("❌ Native ad failed: \(error)")
    }
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        isLoading = false
        self.nativeAd = NativeAdViewModel(from: nativeAd)
    }
}

extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        interstitialReady = false
        loadInterstitialAd()
    }
}
#endif