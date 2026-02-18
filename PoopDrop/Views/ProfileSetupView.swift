import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var displayName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var usernameAvailable = true
    @State private var checkingUsername = false

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Theme.accent.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 24)

                    // Avatar picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let image = avatarImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                            Text("Add Photo")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(.white.opacity(0.6))
                                    )
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                            }

                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                )
                                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        loadPhoto(item)
                    }

                    // Header
                    VStack(spacing: 8) {
                        Text("Set Up Your Profile")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("This is how your friends will see you")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    // Input fields
                    VStack(spacing: 16) {
                        // Display name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DISPLAY NAME")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(1)

                            TextField("Your name", text: $displayName)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                        }

                        // Username
                        VStack(alignment: .leading, spacing: 6) {
                            Text("USERNAME")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(1)

                            HStack {
                                Text("@")
                                    .foregroundStyle(.white.opacity(0.4))
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
                            .background(Color.white.opacity(0.08))
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
                    }
                    .padding(.horizontal, 24)

                    // Continue button
                    Button(action: completeProfile) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Start Dropping!")
                                    .fontWeight(.bold)
                                AppLogoView(size: 20)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? Theme.accent : Theme.accent.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!canContinue || isLoading)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
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

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                avatarImage = image
            }
        }
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
            }
            checkingUsername = false
        }
    }

    private func completeProfile() {
        guard canContinue, var currentUser = authManager.currentUser else { return }
        isLoading = true
        errorMessage = nil

        currentUser.username = username
        currentUser.displayName = displayName.isEmpty ? nil : displayName

        Task {
            do {
                // Upload avatar if selected
                if let image = avatarImage,
                   let jpegData = image.jpegData(compressionQuality: 0.7) {
                    let avatarURL = try await SupabaseManager.shared.uploadAvatar(
                        userID: currentUser.id,
                        imageData: jpegData
                    )
                    currentUser.avatarURL = avatarURL
                }

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
