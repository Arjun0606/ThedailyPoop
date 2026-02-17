import SwiftUI
import UIKit

// MARK: - Share Card Generator
// Renders SwiftUI views as 1080x1920 images (Instagram Story size)
// for viral sharing — gossip teases, drop shares, group invites

@MainActor
struct ShareCardGenerator {

    /// Instagram Story dimensions (9:16)
    static let storySize = CGSize(width: 1080, height: 1920)

    /// Render any SwiftUI view as a UIImage
    static func render<V: View>(_ view: V, size: CGSize = storySize) -> UIImage? {
        let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// Show native share sheet with the generated image
    static func share(image: UIImage, from viewController: UIViewController? = nil) {
        let items: [Any] = [image, "Download TheDailyPoop - the wildest friend group app https://thedailypoop.app"]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)

        let vc = viewController ?? topViewController()
        vc?.present(ac, animated: true)
    }

    /// Helper to find top view controller
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }

        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
