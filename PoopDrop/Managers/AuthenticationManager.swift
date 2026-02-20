import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsProfileSetup = false

    private var currentNonce: String?

    override init() {
        super.init()
        checkAuthenticationState()
    }

    // MARK: - Session Check

    func checkAuthenticationState() {
        Task {
            if let session = await SupabaseManager.shared.getCurrentSession() {
                let userID = session.user.id.uuidString.lowercased()
                if let user = try? await SupabaseManager.shared.fetchUser(id: userID) {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            }
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() {
        isLoading = true
        errorMessage = nil

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Sign Out

    func signOut() {
        print("🚪 Signing out user")
        Task { try? await SupabaseManager.shared.signOut() }
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "currentUserID")
        print("✅ Sign out completed")
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8),
              let nonce = currentNonce else {
            isLoading = false
            errorMessage = "Failed to get Apple ID credential"
            return
        }

        // Extract name from Apple credential (only provided on FIRST sign-in)
        let fullName = credential.fullName
        let givenName = fullName?.givenName
        let familyName = fullName?.familyName

        Task {
            do {
                let (user, isNewUser) = try await SupabaseManager.shared.signInWithApple(
                    idToken: tokenString,
                    nonce: nonce,
                    givenName: givenName,
                    familyName: familyName
                )
                self.currentUser = user
                self.isAuthenticated = true
                self.needsProfileSetup = isNewUser
                UserDefaults.standard.set(user.id, forKey: "currentUserID")
                NotificationCenter.default.post(name: Notification.Name("USER_SIGNED_IN"), object: nil)
            } catch {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = nil // User canceled — don't show error
            default:
                errorMessage = "Sign in failed"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
