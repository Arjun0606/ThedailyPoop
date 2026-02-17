import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var usernameAvailable = true
    @State private var checkingUsername = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.brown.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    Text("💩")
                        .font(.system(size: 80))

                    Text("Pick a Username")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("This is how your friends will see you")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Username field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("@")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.body)

                        TextField("username", text: $username)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, newValue in
                                username = newValue.lowercased()
                                    .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                checkUsernameAvailability()
                            }

                        if checkingUsername {
                            ProgressView().scaleEffect(0.8)
                        } else if !username.isEmpty {
                            Image(systemName: usernameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(usernameAvailable ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                    if !usernameAvailable && !username.isEmpty {
                        Text("Username not available")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if username.count > 0 && username.count < 3 {
                        Text("At least 3 characters")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 32)

                // Continue button
                Button(action: completeProfile) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text("Start Dropping! 💩")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.white : Color.white.opacity(0.3))
                    .cornerRadius(12)
                }
                .disabled(!canContinue || isLoading)
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .alert("Profile Setup Error", isPresented: $showingError) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        .onChange(of: errorMessage) { _, error in
            showingError = error != nil
        }
    }

    private var canContinue: Bool {
        username.count >= 3 && usernameAvailable && !checkingUsername
    }

    private func checkUsernameAvailability() {
        guard username.count >= 3 else {
            usernameAvailable = true
            return
        }

        let isValidFormat = username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
            && !username.hasPrefix("_")
            && !username.hasSuffix("_")

        guard isValidFormat else {
            usernameAvailable = false
            return
        }

        checkingUsername = true

        Task {
            do {
                let available = try await SupabaseManager.shared.isUsernameAvailable(username)
                usernameAvailable = available
            } catch {
                usernameAvailable = false
                print("Username check failed: \(error)")
            }
            checkingUsername = false
        }
    }

    private func completeProfile() {
        guard canContinue, var currentUser = authManager.currentUser else { return }
        isLoading = true
        errorMessage = nil

        currentUser.username = username

        Task {
            do {
                try await SupabaseManager.shared.saveUser(currentUser)
                authManager.currentUser = currentUser
                onComplete()
            } catch {
                errorMessage = "Failed to save profile: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    ProfileSetupView { print("done") }
        .environmentObject(AuthenticationManager())
}
