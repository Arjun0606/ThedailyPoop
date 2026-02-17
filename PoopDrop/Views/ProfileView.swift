import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var showingContact = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingPaywall = false
    @State private var savedStories: [Story] = []
    @State private var selectedStory: Story?

    var user: User? { authManager.currentUser }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if let user = user {
                    ScrollView {
                        VStack(spacing: 24) {
                            ProfileHeaderView(user: user)
                            StreakSection(user: user)
                            SubscriptionSection(
                                isPremium: user.isPremium,
                                onUpgrade: { showingPaywall = true }
                            )

                            // Saved Stories
                            if !savedStories.isEmpty {
                                SavedStoriesSection(
                                    stories: savedStories,
                                    onTap: { story in selectedStory = story }
                                )
                            }

                            InfoLegalSection(
                                onContactTap: { showingContact = true },
                                onTermsTap: { showingTerms = true },
                                onPrivacyTap: { showingPrivacy = true }
                            )

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                } else {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingContact) { ContactView() }
        .sheet(isPresented: $showingTerms) { TermsOfServiceView() }
        .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
                .environmentObject(authManager)
        }
        .task {
            guard let user = authManager.currentUser else { return }
            savedStories = (try? await SupabaseManager.shared.fetchBookmarkedStories(userId: user.id)) ?? []
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            if let url = user.avatarURL,
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brown.opacity(0.7), Color.brown],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }
            }

            VStack(spacing: 8) {
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("@\(user.username)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                Text("Member since \(user.createdAt.formatted(.dateTime.month(.wide).year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Streak Section
struct StreakSection: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Streak")
                .font(.headline.bold())
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                StatCard(
                    icon: "🔥",
                    title: "Current Streak",
                    value: "\(user.streakCount)",
                    color: .orange
                )

                StatCard(
                    icon: "📅",
                    title: "Member Days",
                    value: "\(memberDays)",
                    color: .cyan
                )
            }
        }
    }

    private var memberDays: Int {
        Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
    }
}

// MARK: - Subscription Section
struct SubscriptionSection: View {
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        if isPremium {
            HStack(spacing: 14) {
                Text("⭐")
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium Member")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("All stories unlocked")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
            )
        } else {
            Button(action: onUpgrade) {
                HStack(spacing: 14) {
                    Text("💩")
                        .font(.title)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Unlock all 10 daily stories")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    Text("$7.99/mo")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Info & Legal
struct InfoLegalSection: View {
    let onContactTap: () -> Void
    let onTermsTap: () -> Void
    let onPrivacyTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            InfoLegalRow(icon: "envelope.fill", title: "Contact & Suggestions", color: .green, action: onContactTap)
            Divider().background(Color.white.opacity(0.1))
            InfoLegalRow(icon: "doc.text.fill", title: "Terms of Service", color: .orange, action: onTermsTap)
            Divider().background(Color.white.opacity(0.1))
            InfoLegalRow(icon: "lock.shield.fill", title: "Privacy Policy", color: .purple, action: onPrivacyTap)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct InfoLegalRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var confirmingDelete = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    Section(header: Text("Notifications").foregroundStyle(.white)) {
                        Button("Open System Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(.white)
                    }

                    Section(header: Text("Profile").foregroundStyle(.white)) {
                        NavigationLink("Edit Profile") {
                            EditProfileView()
                        }
                        .foregroundStyle(.white)
                    }

                    Section {
                        Button(action: {
                            authManager.signOut()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundStyle(.red)
                                Text("Sign Out")
                                    .foregroundStyle(.red)
                            }
                        }

                        Button(role: .destructive) {
                            confirmingDelete = true
                        } label: {
                            Text("Delete Account")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Account?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                Task {
                    guard let user = authManager.currentUser else { return }
                    do {
                        try await SupabaseManager.shared.deleteAccount(userID: user.id)
                    } catch {
                        print("Account deletion failed: \(error)")
                    }
                    await MainActor.run {
                        authManager.signOut()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }
}

// MARK: - Edit Profile
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var checking = false
    @State private var available = true

    var body: some View {
        Form {
            Section(header: Text("Username")) {
                HStack {
                    TextField("username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _, _ in debounceCheck() }
                    if checking { ProgressView() }
                    if !username.isEmpty {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(available ? .green : .red)
                    }
                }
            }

            Section {
                Button("Save") { Task { await saveProfile() } }
                    .disabled(!available || username.isEmpty)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            if let u = authManager.currentUser { username = u.username }
        }
    }

    private func debounceCheck() {
        checking = true
        available = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task { await checkUsername() }
        }
    }

    private func checkUsername() async {
        do {
            let ok = try await SupabaseManager.shared.isUsernameAvailable(username)
            await MainActor.run { available = ok; checking = false }
        } catch {
            await MainActor.run { available = false; checking = false }
        }
    }

    private func saveProfile() async {
        guard var user = authManager.currentUser else { return }
        user.username = username
        do {
            try await SupabaseManager.shared.saveUser(user)
            await MainActor.run {
                authManager.currentUser = user
                dismiss()
            }
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

// MARK: - Saved Stories
struct SavedStoriesSection: View {
    let stories: [Story]
    let onTap: (Story) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.brown)
                Text("Saved Stories")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(stories.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ForEach(stories) { story in
                Button { onTap(story) } label: {
                    HStack(spacing: 12) {
                        Text(story.categoryEmoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(story.headline)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text("\(story.categoryLabel) · \(story.readingTimeMinutes) min")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                if story.id != stories.last?.id {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Share Stats
struct ShareStatsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    ShareCard(user: user)
                        .padding(.horizontal)

                    ShareLink(
                        item: "I'm on a \(user.streakCount)-day streak on TheDailyPoop! Join me.",
                        subject: Text("TheDailyPoop"),
                        message: Text("Check out TheDailyPoop - the daily news briefing that's actually fun to read!")
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ShareCard: View {
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            Text("💩")
                .font(.system(size: 40))
            Text("TheDailyPoop")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("@\(user.username)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("🔥").font(.title3)
                    Text("\(user.streakCount)").font(.title2.bold()).foregroundStyle(.white)
                    Text("Streak").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text("📅").font(.title3)
                    let days = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
                    Text("\(days)").font(.title2.bold()).foregroundStyle(.white)
                    Text("Days").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            Text("Your daily scoop — actually fun to read.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(width: 320, height: 320)
        .background(
            LinearGradient(
                colors: [.brown.opacity(0.8), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
