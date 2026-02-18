import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingError = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Subtle radial glow behind logo
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.12),
                    .clear
                ]),
                center: .center,
                startRadius: 10,
                endRadius: 300
            )
            .offset(y: -80)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                VStack(spacing: 24) {
                    AppLogoView(size: 100)
                        .scaleEffect(pulseScale)
                        .shadow(color: Theme.accent.opacity(0.3), radius: 30, x: 0, y: 10)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                pulseScale = 1.08
                            }
                        }

                    VStack(spacing: 8) {
                        Text("TheDailyPoop")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)

                        Text("News that doesn't suck")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()
                Spacer()

                // Sign in area
                VStack(spacing: 20) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authManager.signInWithApple()
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(authManager.isLoading)

                    if authManager.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Theme.textSecondary)
                            Text("Signing in...")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 40)

                // Legal footer
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)

                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            showingTerms = true
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)

                        Text("and")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)

                        Button("Privacy Policy") {
                            showingPrivacy = true
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: authManager.errorMessage) { _, errorMessage in
            showingError = errorMessage != nil
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
