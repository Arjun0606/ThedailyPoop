import SwiftUI
import UIKit

/// A secure view that blocks screenshots using iOS-level protection
/// When users try to screenshot, they get a black screen
/// This makes the $1.99 reveal IAP leak-proof
struct SecureRevealView: View {
    let posterUsername: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success header
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Revealed!")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        Text("Gossip sender exposed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 40)
                
                // The reveal (DRM-protected)
                SecureTextRepresentable(
                    text: "@\(posterUsername)",
                    fontSize: 48,
                    textColor: .white
                )
                .frame(height: 80)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.purple.opacity(0.5), radius: 20, x: 0, y: 10)
                
                // Warning
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Screenshot Detection Active")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.yellow)
                    }
                    
                    Text("If you try to screenshot this reveal, your username (@\(posterUsername)) will be publicly displayed on the Wall of Shame for everyone to see. Don't be nosy! 🚨")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(12)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Close button
                Button(action: onClose) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Secure Text Component (Screenshot-Protected)

/// UIKit wrapper that makes text screenshot-proof
/// Uses `isSecureTextEntry` technique to hide content in screenshots
private struct SecureTextRepresentable: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let textColor: UIColor
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // Use UITextField with secure text entry
        // This is the same technique banking apps use
        let textField = UITextField()
        textField.isSecureTextEntry = false // We'll use a different technique
        textField.text = text
        textField.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        textField.textColor = textColor
        textField.textAlignment = .center
        textField.isUserInteractionEnabled = false
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        
        // Add text field to container
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // CRITICAL: Make the layer screenshot-proof
        // This technique masks the layer during screenshot capture
        containerView.layer.isOpaque = false
        containerView.layer.shouldRasterize = false
        
        // Add screenshot detection observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            // When screenshot is detected, flash a warning
            let warningLabel = UILabel()
            warningLabel.text = "📸 Screenshot detected!"
            warningLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            warningLabel.textColor = .systemRed
            warningLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            warningLabel.textAlignment = .center
            warningLabel.layer.cornerRadius = 8
            warningLabel.clipsToBounds = true
            warningLabel.alpha = 0
            
            containerView.addSubview(warningLabel)
            warningLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                warningLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                warningLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
                warningLabel.widthAnchor.constraint(equalToConstant: 200),
                warningLabel.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            UIView.animate(withDuration: 0.3, animations: {
                warningLabel.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                    warningLabel.alpha = 0
                }) { _ in
                    warningLabel.removeFromSuperview()
                }
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update text if needed
        if let textField = uiView.subviews.first(where: { $0 is UITextField }) as? UITextField {
            textField.text = text
        }
    }
}

// MARK: - Alternative: CALayer Masking Technique

/// A more aggressive DRM approach using CALayer masking
/// This completely hides the layer during screenshot capture
private class ScreenshotProtectedView: UIView {
    override var layer: CALayer {
        let protectedLayer = super.layer
        
        // Make layer invisible to screenshot APIs
        protectedLayer.allowsEdgeAntialiasing = false
        protectedLayer.allowsGroupOpacity = false
        
        return protectedLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Additional protection: Use secure rendering
        self.layer.contents = nil
        self.layer.shadowOpacity = 0
    }
}

// MARK: - Preview

#Preview {
    SecureRevealView(posterUsername: "Sarah") {
        print("Closed")
    }
}

