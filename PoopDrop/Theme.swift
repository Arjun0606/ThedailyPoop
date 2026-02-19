import SwiftUI

// MARK: - Design System
enum Theme {

    // MARK: Category Colors
    static func categoryColor(for category: String) -> Color {
        switch category {
        case "business": return .init(red: 1.0, green: 0.76, blue: 0.28)   // Gold
        case "tech": return .init(red: 0.35, green: 0.78, blue: 1.0)       // Cyan
        case "politics": return .init(red: 1.0, green: 0.45, blue: 0.35)   // Coral
        case "sports": return .init(red: 0.3, green: 0.9, blue: 0.5)       // Green
        case "culture": return .init(red: 0.75, green: 0.45, blue: 1.0)    // Purple
        default: return .white.opacity(0.6)
        }
    }

    static func categoryGradient(for category: String) -> LinearGradient {
        switch category {
        case "business":
            return LinearGradient(colors: [.init(red: 1.0, green: 0.76, blue: 0.28), .init(red: 0.95, green: 0.6, blue: 0.1)], startPoint: .leading, endPoint: .trailing)
        case "tech":
            return LinearGradient(colors: [.init(red: 0.35, green: 0.78, blue: 1.0), .init(red: 0.2, green: 0.5, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
        case "politics":
            return LinearGradient(colors: [.init(red: 1.0, green: 0.45, blue: 0.35), .init(red: 0.9, green: 0.25, blue: 0.3)], startPoint: .leading, endPoint: .trailing)
        case "sports":
            return LinearGradient(colors: [.init(red: 0.3, green: 0.9, blue: 0.5), .init(red: 0.1, green: 0.7, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
        case "culture":
            return LinearGradient(colors: [.init(red: 0.75, green: 0.45, blue: 1.0), .init(red: 0.55, green: 0.25, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
        }
    }

    // MARK: Drop Colors
    static func dropColor(for dropType: String) -> Color {
        switch dropType {
        case "daily": return .init(red: 1.0, green: 0.76, blue: 0.28)     // Warm gold (brand)
        case "morning": return .init(red: 1.0, green: 0.76, blue: 0.28)   // Warm gold
        case "midday": return .init(red: 1.0, green: 0.55, blue: 0.2)     // Hot orange
        case "evening": return .init(red: 0.5, green: 0.4, blue: 1.0)     // Deep indigo
        default: return .white.opacity(0.6)
        }
    }

    // MARK: Brand
    static let accent = Color(red: 1.0, green: 0.76, blue: 0.28)      // Warm gold
    static let accentDim = Color(red: 1.0, green: 0.76, blue: 0.28).opacity(0.15)

    // MARK: Surfaces
    static let cardBg = Color.white.opacity(0.04)
    static let cardBorder = Color.white.opacity(0.08)
    static let elevatedBg = Color.white.opacity(0.06)
    static let glassBg = Color.white.opacity(0.08)

    // MARK: Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // MARK: Spacing
    static let cardRadius: CGFloat = 16
    static let pillRadius: CGFloat = 100
    static let pagePadding: CGFloat = 20
}

// MARK: - Reusable Components

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.5))
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )
    }
}

struct CategoryPill: View {
    let category: String
    let emoji: String

    var body: some View {
        HStack(spacing: 5) {
            Text(emoji)
                .font(.caption2)
            Text(category.capitalized)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .foregroundStyle(Theme.categoryColor(for: category))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.categoryColor(for: category).opacity(0.12))
        .clipShape(Capsule())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AppLogoView: View {
    var size: CGFloat = 80

    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }
}
