import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var showingContact = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var groups: [Group] = []
    @State private var refreshTrigger = false

    var user: User? { authManager.currentUser }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if let user = user {
                    ScrollView {
                        VStack(spacing: 24) {
                            ProfileHeaderView(user: user)
                            GoldenInvitesSection()
                            StatsSection(user: user, refreshTrigger: refreshTrigger)
                            MyGroupsSection(groups: groups)

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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_STATS_UPDATED"))) { _ in
            refreshTrigger.toggle()
        }
        .task { await loadGroups() }
    }

    private func loadGroups() async {
        guard let user = user else { return }
        do {
            groups = try await SupabaseManager.shared.fetchMyGroups(userID: user.id)
        } catch {
            print("Failed to load groups: \(error)")
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
                Text(user.username)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

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

// MARK: - Stats Section
struct StatsSection: View {
    let user: User
    let refreshTrigger: Bool
    @State private var showingShare = false

    var memberDays: Int {
        Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Stats")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Spacer()

                Button(action: { showingShare = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        Text("Share")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }

            HStack(spacing: 12) {
                StatCard(icon: "💩", title: "Total Drops", value: "\(user.totalDrops)", color: .brown)
                StatCard(icon: "📅", title: "Member Days", value: "\(memberDays)", color: .cyan)
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareStatsView(user: user)
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

// MARK: - Golden Invites Section (profile page)
struct GoldenInvitesSection: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var inviteCodes: [String] = []
    @State private var usedCodes: Set<String> = []
    @State private var isLoading = true
    @State private var showingInvites = false

    var remaining: Int {
        inviteCodes.filter { !usedCodes.contains($0) }.count
    }

    var body: some View {
        Button(action: { showingInvites = true }) {
            HStack(spacing: 14) {
                Text("🎟️")
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Golden Invites")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(isLoading ? "Loading..." : "\(remaining) remaining")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.caption)
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
        }
        .sheet(isPresented: $showingInvites) {
            NavigationView {
                GoldenInvitesView()
                    .navigationTitle("Invites")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingInvites = false }
                                .foregroundStyle(.white)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .task { await loadInvites() }
    }

    private func loadInvites() async {
        guard let user = authManager.currentUser else { return }
        do {
            let result = try await SupabaseManager.shared.fetchUserInvites(userID: user.id)
            inviteCodes = result.codes
            usedCodes = Set(result.usedCodes)
        } catch {
            // Demo fallback
            inviteCodes = ["DEMO01", "DEMO02", "DEMO03"]
        }
        isLoading = false
    }
}

// MARK: - My Groups Section
struct MyGroupsSection: View {
    let groups: [Group]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Groups")
                .font(.headline.bold())
                .foregroundStyle(.white)

            if groups.isEmpty {
                HStack {
                    Text("No groups yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            } else {
                ForEach(groups) { group in
                    HStack(spacing: 12) {
                        Text(group.emoji)
                            .font(.title2)
                        Text(group.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(group.inviteCode)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
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

// MARK: - Share Stats
struct ShareStatsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var memberDays: Int {
        Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    if let image = shareImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(20)
                            .padding(.horizontal)
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(height: 400)
                    }

                    Button(action: shareStats) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share to Socials")
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
        .onAppear { generateShareImage() }
    }

    private func generateShareImage() {
        let card = ShareCard(user: user, memberDays: memberDays)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        shareImage = renderer.uiImage
    }

    private func shareStats() {
        guard let image = shareImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           var topController = window.rootViewController {
            while let presented = topController.presentedViewController {
                topController = presented
            }
            activityVC.popoverPresentationController?.sourceView = topController.view
            topController.present(activityVC, animated: true)
        }
    }
}

struct ShareCard: View {
    let user: User
    let memberDays: Int

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
                    Text("💩").font(.title3)
                    Text("\(user.totalDrops)").font(.title2.bold()).foregroundStyle(.white)
                    Text("Drops").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text("📅").font(.title3)
                    Text("\(memberDays)").font(.title2.bold()).foregroundStyle(.white)
                    Text("Days").font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }

            Text("Join me on TheDailyPoop!")
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

// UIKit share sheet wrapper
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
