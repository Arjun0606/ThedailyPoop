import Foundation
import AuthenticationServices
import CloudKit
import Combine

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        // Check if user is already signed in with Apple ID
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        if let userID = UserDefaults.standard.string(forKey: "appleUserID") {
            appleIDProvider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        self?.isAuthenticated = true
                        self?.loadCurrentUser()
                    case .revoked, .notFound:
                        self?.signOut()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "currentUserID")
    }
    
    private func loadCurrentUser() {
        guard let userID = UserDefaults.standard.string(forKey: "currentUserID") else {
            return
        }
        
        // Load user from CloudKit
        Task {
            do {
                let user = try await CloudKitManager.shared.fetchUser(id: userID)
                await MainActor.run {
                    self.currentUser = user
                }
            } catch {
                print("Failed to load current user: \(error)")
            }
        }
    }
    
    private func createUserFromAppleID(_ authorization: ASAuthorizationAppleIDCredential) async {
        let userID = authorization.user
        let fullName = authorization.fullName
        let email = authorization.email
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
            .isEmpty ? "Poop Dropper" : [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let user = User(
            id: userID,
            displayName: displayName
        )
        
        do {
            try await CloudKitManager.shared.saveUser(user)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                UserDefaults.standard.set(userID, forKey: "appleUserID")
                UserDefaults.standard.set(userID, forKey: "currentUserID")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create user account: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await createUserFromAppleID(appleIDCredential)
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.errorMessage = "Sign in was canceled"
                case .failed:
                    self.errorMessage = "Sign in failed"
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple"
                case .notHandled:
                    self.errorMessage = "Sign in not handled"
                case .unknown:
                    self.errorMessage = "Unknown error occurred"
                @unknown default:
                    self.errorMessage = "An unexpected error occurred"
                }
            } else {
                self.errorMessage = error.localizedDescription
            }
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
import CloudKit
import Combine

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        // Check if user is already signed in with Apple ID
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        if let userID = UserDefaults.standard.string(forKey: "appleUserID") {
            appleIDProvider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        self?.isAuthenticated = true
                        self?.loadCurrentUser()
                    case .revoked, .notFound:
                        self?.signOut()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "currentUserID")
    }
    
    private func loadCurrentUser() {
        guard let userID = UserDefaults.standard.string(forKey: "currentUserID") else {
            return
        }
        
        // Load user from CloudKit
        Task {
            do {
                let user = try await CloudKitManager.shared.fetchUser(id: userID)
                await MainActor.run {
                    self.currentUser = user
                }
            } catch {
                print("Failed to load current user: \(error)")
            }
        }
    }
    
    private func createUserFromAppleID(_ authorization: ASAuthorizationAppleIDCredential) async {
        let userID = authorization.user
        let fullName = authorization.fullName
        let email = authorization.email
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
            .isEmpty ? "Poop Dropper" : [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let user = User(
            id: userID,
            displayName: displayName
        )
        
        do {
            try await CloudKitManager.shared.saveUser(user)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                UserDefaults.standard.set(userID, forKey: "appleUserID")
                UserDefaults.standard.set(userID, forKey: "currentUserID")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create user account: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await createUserFromAppleID(appleIDCredential)
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    self.errorMessage = "Sign in was canceled"
                case .failed:
                    self.errorMessage = "Sign in failed"
                case .invalidResponse:
                    self.errorMessage = "Invalid response from Apple"
                case .notHandled:
                    self.errorMessage = "Sign in not handled"
                case .unknown:
                    self.errorMessage = "Unknown error occurred"
                @unknown default:
                    self.errorMessage = "An unexpected error occurred"
                }
            } else {
                self.errorMessage = error.localizedDescription
            }
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
