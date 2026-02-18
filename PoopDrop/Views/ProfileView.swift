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
    @State private var showingShareStats = false

    var user: User? { authManager.currentUser }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let user = user {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Top bar
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("You")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundStyle(.white)
                                Text("@\(user.username)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            Spacer()

                            Button { showingShareStats = true } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.cardBg)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 0.5))
                            }

                            Button { showingSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.cardBg)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, Theme.pagePadding)
                        .padding(.top, 16)

                        // Profile card
                        ProfileHeaderCard(user: user)
                            .padding(.horizontal, Theme.pagePadding)

                        // Stats row
                        HStack(spacing: 12) {
                            StatCard(
                                value: "\(user.streakCount)",
                                label: "Streak",
                                icon: "flame.fill",
                                color: .orange
                            )

                            StatCard(
                                value: "\(memberDays(for: user))",
                                label: "Days",
                                icon: "calendar",
                                color: .cyan
                            )

                            StatCard(
                                value: "\(savedStories.count)",
                                label: "Saved",
                                icon: "bookmark.fill",
                                color: Theme.accent
                            )
                        }
                        .padding(.horizontal, Theme.pagePadding)

                        // Subscription card
                        SubscriptionCard(
                            isPremium: user.isPremium,
                            onUpgrade: { showingPaywall = true }
                        )
                        .padding(.horizontal, Theme.pagePadding)

                        // Streak visualization
                        StreakCard(user: user)
                            .padding(.horizontal, Theme.pagePadding)

                        // Saved Stories
                        if !savedStories.isEmpty {
                            SavedStoriesSection(
                                stories: savedStories,
                                onTap: { story in selectedStory = story }
                            )
                            .padding(.horizontal, Theme.pagePadding)
                        }

                        // Legal
                        InfoLegalSection(
                            onContactTap: { showingContact = true },
                            onTermsTap: { showingTerms = true },
                            onPrivacyTap: { showingPrivacy = true }
                        )
                        .padding(.horizontal, Theme.pagePadding)

                        // Version
                        Text("TheDailyPoop v1.0")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Theme.textSecondary)
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingContact) { ContactView() }
        .sheet(isPresented: $showingTerms) { TermsOfServiceView() }
        .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingShareStats) {
            if let user = user {
                ShareStatsView(user: user)
            }
        }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
                .environmentObject(authManager)
        }
        .task {
            guard let user = authManager.currentUser else { return }
            savedStories = (try? await SupabaseManager.shared.fetchBookmarkedStories(userId: user.id)) ?? []
        }
    }

    private func memberDays(for user: User) -> Int {
        Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
    }
}

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    let user: User

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            if let url = user.avatarURL,
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.accent.opacity(0.4), lineWidth: 2))
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.6), Theme.accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if let displayName = user.displayName, !displayName.isEmpty {
                    Text(displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("@\(user.username)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Text("Member since \(user.createdAt.formatted(.dateTime.month(.abbreviated).year()))")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let user: User

    private var weekDays: [String] { ["M", "T", "W", "T", "F", "S", "S"] }
    private var todayIndex: Int { (Calendar.current.component(.weekday, from: Date()) + 5) % 7 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Reading Streak")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(user.streakCount) day\(user.streakCount == 1 ? "" : "s")")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            }

            // Week dots
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 8) {
                        Text(weekDays[i])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)

                        ZStack {
                            Circle()
                                .fill(i <= todayIndex ? .orange.opacity(0.15) : Theme.cardBg)
                                .frame(width: 32, height: 32)

                            if i < todayIndex && i >= todayIndex - min(user.streakCount, todayIndex) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.orange)
                            } else if i == todayIndex {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - Subscription Card
struct SubscriptionCard: View {
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        if isPremium {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium Member")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("All stories unlocked")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Theme.accent.opacity(0.08), Theme.accent.opacity(0.02)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
            )
        } else {
            Button(action: onUpgrade) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Unlock all daily stories")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(16)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                )
            }
            .buttonStyle(PressableButtonStyle())
        }
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
            Divider().background(Theme.cardBorder)
            InfoLegalRow(icon: "doc.text.fill", title: "Terms of Service", color: .orange, action: onTermsTap)
            Divider().background(Theme.cardBorder)
            InfoLegalRow(icon: "lock.shield.fill", title: "Privacy Policy", color: .purple, action: onPrivacyTap)
        }
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
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
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.textTertiary)
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

                ScrollView {
                    VStack(spacing: 16) {
                        // Notifications
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NOTIFICATIONS")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(0.5)
                                .padding(.horizontal, 4)

                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.red.opacity(0.12))
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "bell.badge.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.red)
                                    }
                                    Text("Push Notifications")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                .padding(16)
                                .background(Theme.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                            }
                        }

                        // Profile
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PROFILE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(0.5)
                                .padding(.horizontal, 4)

                            NavigationLink {
                                EditProfileView()
                            } label: {
                                HStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.blue.opacity(0.12))
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.blue)
                                    }
                                    Text("Edit Profile")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Theme.textTertiary)
                                }
                                .padding(16)
                                .background(Theme.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                            }
                        }

                        // Account actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCOUNT")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(0.5)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                Button {
                                    authManager.signOut()
                                    dismiss()
                                } label: {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.orange.opacity(0.12))
                                                .frame(width: 30, height: 30)
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.orange)
                                        }
                                        Text("Sign Out")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }

                                Divider().background(Theme.cardBorder)

                                Button {
                                    confirmingDelete = true
                                } label: {
                                    HStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.red.opacity(0.12))
                                                .frame(width: 30, height: 30)
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.red)
                                        }
                                        Text("Delete Account")
                                            .font(.subheadline)
                                            .foregroundStyle(.red)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(Theme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                                    .stroke(Theme.cardBorder, lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, Theme.pagePadding)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("USERNAME")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(0.5)

                    HStack(spacing: 12) {
                        Text("@")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textTertiary)

                        TextField("username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.title3)
                            .foregroundStyle(.white)
                            .onChange(of: username) { _, _ in debounceCheck() }

                        if checking {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        if !username.isEmpty && !checking {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(available ? .green : .red)
                                .font(.title3)
                        }
                    }
                    .padding(16)
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .stroke(
                                !username.isEmpty && !checking ?
                                    (available ? Color.green.opacity(0.3) : Color.red.opacity(0.3)) :
                                    Theme.cardBorder,
                                lineWidth: 0.5
                            )
                    )
                }

                Button {
                    Task { await saveProfile() }
                } label: {
                    Text("Save Changes")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!available || username.isEmpty)
                .opacity(!available || username.isEmpty ? 0.4 : 1)

                Spacer()
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 24)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 13))
                Text("Saved Stories")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(stories.count)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.cardBg)
                    .clipShape(Capsule())
            }

            ForEach(stories) { story in
                Button { onTap(story) } label: {
                    HStack(spacing: 12) {
                        // Category dot
                        Circle()
                            .fill(Theme.categoryColor(for: story.category))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(story.headline)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 6) {
                                Text(story.categoryEmoji)
                                    .font(.caption2)
                                Text(story.categoryLabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Theme.categoryColor(for: story.category))
                                Text("\(story.readingTimeMinutes) min")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if story.id != stories.last?.id {
                    Divider().background(Theme.cardBorder)
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
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

                VStack(spacing: 24) {
                    Spacer()

                    ShareCard(user: user)

                    ShareLink(
                        item: "I'm on a \(user.streakCount)-day streak on TheDailyPoop! Join me.",
                        subject: Text("TheDailyPoop"),
                        message: Text("Check out TheDailyPoop - the daily news briefing that's actually fun to read!")
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, Theme.pagePadding)

                    Spacer()
                }
            }
            .navigationTitle("Share Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ShareCard: View {
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            AppLogoView(size: 48)

            VStack(spacing: 4) {
                Text("TheDailyPoop")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    Text("\(user.streakCount)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Streak")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                    let days = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
                    Text("\(days)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Days")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text("Your daily scoop — actually fun to read.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .frame(width: 300, height: 320)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.08), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
