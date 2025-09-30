import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingError = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color.black, Color.brown.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App logo and title
                VStack(spacing: 20) {
                    Text("💩")
                        .font(.system(size: 120))
                        .scaleEffect(authManager.isLoading ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: authManager.isLoading)
                    
                    VStack(spacing: 8) {
                        Text("Poop Drop")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Drop it like it's hot! 🔥")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Sign in section
                VStack(spacing: 24) {
                    Text("Ready to start dropping?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Sign in with Apple button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            authManager.signInWithApple()
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .disabled(authManager.isLoading)
                    
                    if authManager.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Signing in...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Terms and privacy
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            showingTerms = true
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button("Privacy Policy") {
                            showingPrivacy = true
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
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
        .onChange(of: authManager.errorMessage) { errorMessage in
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
