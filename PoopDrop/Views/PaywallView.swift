import SwiftUI

// MARK: - Full-Screen Paywall (sheet presentation)

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanOption = .annual

    enum PlanOption {
        case monthly, annual
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Theme.pagePadding)

                    // Hero
                    VStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text("Unlock Everything")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(.white)

                        Text("Read every story. Play every game.\nJoin the leaderboard.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Features
                    VStack(spacing: 16) {
                        featureRow(icon: "newspaper.fill", text: "All 20 daily stories", sub: "Not just 10")
                        featureRow(icon: "gamecontroller.fill", text: "3 Word Drop games daily", sub: "Free gets 1")
                        featureRow(icon: "hand.thumbsup.fill", text: "Poop or Scoop", sub: "Real or fake headlines")
                        featureRow(icon: "trophy.fill", text: "Public leaderboard", sub: "Flex on your friends")
                        featureRow(icon: "headphones", text: "Audio briefings", sub: "Listen hands-free")
                        featureRow(icon: "clock.arrow.circlepath", text: "10-day archive", sub: "Free gets 3 days")
                    }
                    .padding(.horizontal, Theme.pagePadding)

                    // Indie-dev honesty
                    VStack(spacing: 4) {
                        Text("We don't do ads.\nIf you get Pro, I can afford my own food\nand stop stealing from the pigeon\noutside my window.")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                        Text("Do it for the pigeon.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.pagePadding)

                    // Plan picker
                    VStack(spacing: 12) {
                        planCard(
                            plan: .annual,
                            title: "Annual",
                            price: "$4.99/mo",
                            detail: "$59.99/year",
                            badge: "SAVE 38%"
                        )

                        planCard(
                            plan: .monthly,
                            title: "Monthly",
                            price: "$7.99/mo",
                            detail: "Cancel anytime",
                            badge: nil
                        )
                    }
                    .padding(.horizontal, Theme.pagePadding)

                    // CTA
                    Button {
                        Task {
                            let productID = selectedPlan == .annual
                                ? SubscriptionManager.annualProductID
                                : SubscriptionManager.monthlyProductID
                            let success = await subscriptionManager.purchase(productID: productID)
                            if success { dismiss() }
                        }
                    } label: {
                        HStack {
                            if subscriptionManager.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Subscribe Now")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(subscriptionManager.isLoading)
                    .padding(.horizontal, Theme.pagePadding)

                    // Restore + terms
                    VStack(spacing: 8) {
                        Button {
                            Task { _ = await subscriptionManager.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Text("Cancel anytime. Subscription auto-renews.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, text: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.accent)
        }
    }

    // MARK: - Plan Card

    private func planCard(plan: PlanOption, title: String, price: String, detail: String, badge: String?) -> some View {
        Button { selectedPlan = plan } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(.system(size: 17, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(selectedPlan == plan ? Theme.accent.opacity(0.08) : Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selectedPlan == plan ? Theme.accent : Theme.cardBorder, lineWidth: selectedPlan == plan ? 1.5 : 0.5)
            )
        }
    }
}

// MARK: - Inline Soft Paywall Card (appears after free stories in feed)

struct InlinePaywallCard: View {
    let remainingCount: Int
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Gradient border top
            Rectangle()
                .fill(LinearGradient(
                    colors: [Theme.accent, Theme.accent.opacity(0.3)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 2)

            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)

                    Text("\(remainingCount) more stories waiting")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }

                Text("You've read all free stories in this drop.\nUpgrade to unlock everything.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: onUpgrade) {
                    Text("Unlock All Stories")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Text("Upgrade to PRO \u{2022} Cancel anytime")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.bottom, 16)
        }
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 8)
    }
}
