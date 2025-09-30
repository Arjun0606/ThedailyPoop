import Foundation
import SwiftUI

// MARK: - Animation Manager for Pro Features
@MainActor
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var isAnimating = false
    
    // MARK: - Lottie Animation Names
    enum PoopAnimation: String, CaseIterable {
        case staticPoop = "static_poop" // Free users
        case rainbowPoop = "rainbow_poop_animated" // Pro
        case discoPoop = "disco_poop_animated" // Pro
        case goldPoop = "gold_poop_animated" // Pro
        case firePoop = "fire_poop_animated" // Pro
        case icePoop = "ice_poop_animated" // Pro
        case seasonalPoop = "seasonal_poop_animated" // Pro
        
        var isProOnly: Bool {
            switch self {
            case .staticPoop:
                return false
            default:
                return true
            }
        }
        
        var displayName: String {
            switch self {
            case .staticPoop: return "Classic Poop"
            case .rainbowPoop: return "Rainbow Poop"
            case .discoPoop: return "Disco Poop"
            case .goldPoop: return "Golden Poop"
            case .firePoop: return "Fire Poop"
            case .icePoop: return "Ice Poop"
            case .seasonalPoop: return "Seasonal Poop"
            }
        }
        
        var emoji: String {
            switch self {
            case .staticPoop: return "💩"
            case .rainbowPoop: return "🌈💩"
            case .discoPoop: return "🕺💩"
            case .goldPoop: return "👑💩"
            case .firePoop: return "🔥💩"
            case .icePoop: return "❄️💩"
            case .seasonalPoop: return "🎃💩"
            }
        }
    }
    
    enum StreakAnimation: String {
        case staticFire = "static_fire" // Free users
        case animatedFire = "animated_fire" // Pro users
        case megaFire = "mega_fire" // Pro users (10+ streak)
        case legendaryFire = "legendary_fire" // Pro users (50+ streak)
        
        static func forStreak(_ streak: Int, isPro: Bool) -> StreakAnimation {
            if !isPro {
                return .staticFire
            }
            
            switch streak {
            case 50...:
                return .legendaryFire
            case 10...:
                return .megaFire
            default:
                return .animatedFire
            }
        }
        
        var displayEmoji: String {
            switch self {
            case .staticFire: return "🔥"
            case .animatedFire: return "🔥"
            case .megaFire: return "🔥🔥"
            case .legendaryFire: return "🔥🔥🔥"
            }
        }
    }
    
    // MARK: - Drop Animations
    func getDropAnimation(for skinId: String?, isPro: Bool) -> PoopAnimation {
        guard isPro, let skinId = skinId else {
            return .staticPoop
        }
        
        // Map skin IDs to animations
        switch skinId {
        case "🌈💩": return .rainbowPoop
        case "✨💩": return .discoPoop
        case "👑💩": return .goldPoop
        case "🔥💩": return .firePoop
        case "❄️💩": return .icePoop
        case "🎃💩": return .seasonalPoop
        default: return .staticPoop
        }
    }
    
    func getStreakAnimation(for streak: Int, isPro: Bool) -> StreakAnimation {
        return StreakAnimation.forStreak(streak, isPro: isPro)
    }
    
    // MARK: - Animation Triggers
    func playDropAnimation(_ animation: PoopAnimation) async {
        isAnimating = true
        
        // Simulate animation duration
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        isAnimating = false
    }
    
    func playStreakAnimation(_ animation: StreakAnimation) async {
        isAnimating = true
        
        // Simulate animation duration
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        isAnimating = false
    }
}

// MARK: - Lottie Animation View (SwiftUI Wrapper)
struct LottieAnimationView: View {
    let animationName: String
    let loopMode: LottieLoopMode
    let size: CGSize
    
    enum LottieLoopMode {
        case playOnce
        case loop
        case autoReverse
    }
    
    init(_ animationName: String, 
         loopMode: LottieLoopMode = .playOnce, 
         size: CGSize = CGSize(width: 100, height: 100)) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.size = size
    }
    
    var body: some View {
        // This would be replaced with actual Lottie implementation
        // For now, showing emoji with animation effects
        ZStack {
            if animationName.contains("rainbow") {
                Text("🌈💩")
                    .font(.system(size: size.width * 0.6))
                    .scaleEffect(loopMode == .loop ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: loopMode == .loop)
            } else if animationName.contains("disco") {
                Text("✨💩")
                    .font(.system(size: size.width * 0.6))
                    .rotationEffect(.degrees(loopMode == .loop ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: loopMode == .loop)
            } else if animationName.contains("gold") {
                Text("👑💩")
                    .font(.system(size: size.width * 0.6))
                    .scaleEffect(loopMode == .loop ? 1.3 : 1.0)
                    .animation(.bouncy(duration: 1).repeatForever(autoreverses: true), value: loopMode == .loop)
            } else if animationName.contains("fire") {
                if animationName.contains("legendary") {
                    Text("🔥🔥🔥")
                        .font(.system(size: size.width * 0.4))
                        .scaleEffect(loopMode == .loop ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: loopMode == .loop)
                } else if animationName.contains("mega") {
                    Text("🔥🔥")
                        .font(.system(size: size.width * 0.5))
                        .scaleEffect(loopMode == .loop ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: loopMode == .loop)
                } else {
                    Text("🔥")
                        .font(.system(size: size.width * 0.6))
                        .scaleEffect(loopMode == .loop ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: loopMode == .loop)
                }
            } else {
                // Static poop for free users
                Text("💩")
                    .font(.system(size: size.width * 0.6))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Pro Animation Selector
struct ProAnimationSelector: View {
    @Binding var selectedAnimation: AnimationManager.PoopAnimation
    let isPro: Bool
    let onProRequired: () -> Void
    
    private let animations = AnimationManager.PoopAnimation.allCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Poop Style")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if isPro {
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(animations, id: \.self) { animation in
                    Button(action: {
                        if animation.isProOnly && !isPro {
                            onProRequired()
                        } else {
                            selectedAnimation = animation
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                LottieAnimationView(
                                    animation.rawValue,
                                    loopMode: animation.isProOnly ? .loop : .playOnce,
                                    size: CGSize(width: 60, height: 60)
                                )
                                
                                // Lock overlay for Pro-only animations
                                if animation.isProOnly && !isPro {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.yellow)
                                            .font(.title3)
                                    }
                                }
                            }
                            
                            Text(animation.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedAnimation == animation ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedAnimation == animation ? Color.white.opacity(0.5) : 
                                            (animation.isProOnly && !isPro ? Color.yellow.opacity(0.5) : Color.clear),
                                            lineWidth: selectedAnimation == animation ? 2 : 1
                                        )
                                )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Animated Streak Display
struct AnimatedStreakView: View {
    let streak: Int
    let isPro: Bool
    @StateObject private var animationManager = AnimationManager.shared
    
    private var streakAnimation: AnimationManager.StreakAnimation {
        animationManager.getStreakAnimation(for: streak, isPro: isPro)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            LottieAnimationView(
                streakAnimation.rawValue,
                loopMode: isPro ? .loop : .playOnce,
                size: CGSize(width: 20, height: 20)
            )
            
            Text("\(streak)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isPro ? .orange : .white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPro ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
        )
    }
}

// MARK: - Asset Recommendations
/*
 RECOMMENDED LOTTIE ASSETS TO PURCHASE:
 
 1. IconScout Lottie Animations:
    - Animated Poop Collection: https://iconscout.com/lottie/poop
    - Fire Animations: https://iconscout.com/lottie/fire
    - Rainbow Effects: https://iconscout.com/lottie/rainbow
    - Sparkle/Disco Effects: https://iconscout.com/lottie/sparkle
    - Crown/Gold Effects: https://iconscout.com/lottie/crown
 
 2. LottieFiles Marketplace:
    - Poop Emoji Animations
    - Streak Fire Animations
    - Celebration Effects
 
 3. Custom Animation Requirements:
    - 60fps smooth animations
    - Loop-friendly for Pro features
    - Small file sizes (<100KB each)
    - Consistent style/color scheme
 
 4. Sound Effects (to pair with animations):
    - Fart sounds (5 variations)
    - Flush sounds (3 variations)
    - Plopper/splash sounds (4 variations)
    - Badge unlock celebration sound
    - Streak milestone sounds
 */
