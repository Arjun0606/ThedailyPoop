import SwiftUI

// MARK: - Invite-Only Waitlist (Clubhouse Model)
// No school gates. Pure exclusivity: "You need an invite to get in."
// Each user gets 3 golden invites → invites become social currency.
// Reddit/Product Hunt → waitlist page → drip access → invites spread organically.

struct WaitlistView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var position: Int = 0
    @State private var totalWaiting: Int = 0
    @State private var invitesRemaining: Int = 3
    @State private var hasInviteCode = false
    @State private var enteredCode = ""
    @State private var isChecking = false
    @State private var isOnWaitlist = false
    @State private var codeError: String?
    @State private var showingInviteShare = false

    var body: some View {
        ZStack {
            // Dark gradient
            LinearGradient(
                colors: [Color(hex: "0a0a0a"), Color(hex: "1a0a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("💩")
                            .font(.system(size: 80))

                        Text("TheDailyPoop")
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text("invite only")
                            .font(.title3.weight(.light))
                            .foregroundStyle(.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(4)
                    }
                    .padding(.top, 60)

                    if !isOnWaitlist {
                        // Landing: enter invite code or join waitlist
                        landingSection
                    } else {
                        // On waitlist: show position + share to move up
                        waitlistSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingInviteShare) {
            InviteShareSheet(
                position: position,
                onShared: {
                    showingInviteShare = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Landing (no account yet on waitlist)

    private var landingSection: some View {
        VStack(spacing: 28) {
            // Pitch
            VStack(spacing: 12) {
                Text("Anonymous gossip.\nPaid reveals.\nFriend group chaos.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Post anonymous gossip about your friends.\nThey pay $1.99 to find out it was you.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            // Have an invite code?
            VStack(spacing: 16) {
                Text("Got an invite?")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    TextField("INVITE CODE", text: $enteredCode)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .onChange(of: enteredCode) { _, newValue in
                            enteredCode = String(newValue.prefix(8)).uppercased()
                            codeError = nil
                        }
                }

                if let error = codeError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(action: redeemInviteCode) {
                    if isChecking {
                        ProgressView().tint(.black)
                    } else {
                        Text("Enter")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(enteredCode.count >= 6 ? Color.white : Color.gray)
                .cornerRadius(14)
                .disabled(enteredCode.count < 6 || isChecking)
            }
            .padding(24)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Divider
            HStack {
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            }

            // Join waitlist
            Button(action: joinWaitlist) {
                VStack(spacing: 6) {
                    Text("Join the Waitlist")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("We'll let you in when it's your turn")
                        .font(.caption)
                        .opacity(0.7)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }

            // Social proof
            socialProofSection
        }
    }

    // MARK: - Waitlist Section (already on waitlist)

    private var waitlistSection: some View {
        VStack(spacing: 28) {
            // Position card
            VStack(spacing: 12) {
                Text("You're on the list")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)

                Text("#\(position)")
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)

                Text("\(totalWaiting) people waiting")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
            )

            // Move up the line
            VStack(spacing: 16) {
                Text("Skip the line")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Share TheDailyPoop and move up faster.\nEvery friend who joins bumps you up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: { showingInviteShare = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                        Text("Share & Move Up")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.yellow)
                    .cornerRadius(14)
                }
            }
            .padding(24)
            .background(Color.white.opacity(0.05))
            .cornerRadius(20)

            // FOMO ticker
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Live")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                VStack(spacing: 8) {
                    FOMORow(emoji: "🔥", text: "Someone just got in with an invite", time: "1m ago")
                    FOMORow(emoji: "💀", text: "47 people joined the waitlist", time: "8m ago")
                    FOMORow(emoji: "😈", text: "A group just hit 20 members", time: "15m ago")
                    FOMORow(emoji: "💸", text: "Someone paid $1.99 to reveal gossip", time: "22m ago")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)

            // Already have code?
            VStack(spacing: 12) {
                Text("Got an invite code from a friend?")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 12) {
                    TextField("CODE", text: $enteredCode)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .onChange(of: enteredCode) { _, newValue in
                            enteredCode = String(newValue.prefix(8)).uppercased()
                            codeError = nil
                        }

                    Button(action: redeemInviteCode) {
                        if isChecking {
                            ProgressView().tint(.white)
                        } else {
                            Text("Redeem")
                                .font(.subheadline.bold())
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(enteredCode.count >= 6 ? Color.white.opacity(0.15) : Color.clear)
                    .cornerRadius(10)
                    .disabled(enteredCode.count < 6 || isChecking)
                }

                if let error = codeError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
        }
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        VStack(spacing: 12) {
            // Fake avatars
            HStack(spacing: -10) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(
                            [Color.purple, .blue, .red, .orange, .pink, .green][i]
                                .opacity(0.7)
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(["😂", "💀", "🔥", "👻", "😈", "🤡"][i])
                                .font(.caption2)
                        )
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2)
                        )
                }
            }

            Text("4,200+ people on the waitlist")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.6))

            Text("iykyk")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
                .italic()
        }
    }

    // MARK: - Actions

    private func joinWaitlist() {
        guard let user = authManager.currentUser else { return }
        isChecking = true

        Task {
            do {
                let result = try await SupabaseManager.shared.joinWaitlist(
                    userID: user.id,
                    schoolName: "" // No school in Clubhouse model
                )
                position = result.position
                totalWaiting = result.totalWaiting
            } catch {
                // Fallback for demo
                position = Int.random(in: 80...400)
                totalWaiting = Int.random(in: 400...1200)
            }
            isOnWaitlist = true
            isChecking = false
        }
    }

    private func redeemInviteCode() {
        guard let user = authManager.currentUser else { return }
        isChecking = true
        codeError = nil

        Task {
            do {
                let valid = try await SupabaseManager.shared.redeemInviteCode(
                    code: enteredCode,
                    userID: user.id
                )
                if valid {
                    // They're in!
                    UserDefaults.standard.set(true, forKey: "waitlistCompleted")
                    UserDefaults.standard.set(3, forKey: "invitesRemaining")
                    NotificationCenter.default.post(
                        name: Notification.Name("WAITLIST_COMPLETED"),
                        object: nil
                    )
                } else {
                    codeError = "Invalid or already used invite code."
                }
            } catch {
                codeError = "Invalid or already used invite code."
            }
            isChecking = false
        }
    }
}

// MARK: - FOMO Row

struct FOMORow: View {
    let emoji: String
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(time)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - Invite Share Sheet (for users already in the app)

struct InviteShareSheet: View {
    let position: Int
    let onShared: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("📲")
                    .font(.system(size: 56))
                    .padding(.top, 20)

                Text("Tell a friend")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Every friend who joins bumps you closer to the front")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    let message = "You need to get on TheDailyPoop. Anonymous gossip app where people pay $1.99 to find out who said what. I'm #\(position) on the waitlist 💩\n\nhttps://thedailypoop.app"
                    let ac = UIActivityViewController(
                        activityItems: [message],
                        applicationActivities: nil
                    )
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let root = window.rootViewController {
                        var top = root
                        while let presented = top.presentedViewController {
                            top = presented
                        }
                        top.present(ac, animated: true)
                    }
                    onShared()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                        Text("Share")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.yellow)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Golden Invites View (shown inside the app after access)
// Users who are IN get 3 invites to share. Each invite is a unique code.

struct GoldenInvitesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var inviteCodes: [String] = []
    @State private var usedCodes: Set<String> = []
    @State private var isLoading = true

    var remainingInvites: Int {
        inviteCodes.count - usedCodes.count
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("🎟️")
                    .font(.system(size: 48))

                Text("Your Golden Invites")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("\(remainingInvites) remaining — choose wisely")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            if isLoading {
                ProgressView().tint(.white)
            } else {
                // Invite codes
                VStack(spacing: 12) {
                    ForEach(inviteCodes, id: \.self) { code in
                        let isUsed = usedCodes.contains(code)

                        HStack(spacing: 16) {
                            Text(code)
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(isUsed ? .white.opacity(0.3) : .yellow)

                            Spacer()

                            if isUsed {
                                Text("Used")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                            } else {
                                Button(action: { shareInviteCode(code) }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.caption)
                                        Text("Send")
                                            .font(.caption.bold())
                                    }
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.yellow)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(isUsed ? 0.02 : 0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isUsed ? Color.clear : Color.yellow.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task { await loadInvites() }
    }

    private func loadInvites() async {
        guard let user = authManager.currentUser else { return }
        do {
            let result = try await SupabaseManager.shared.fetchUserInvites(userID: user.id)
            inviteCodes = result.codes
            usedCodes = Set(result.usedCodes)
        } catch {
            // Generate demo codes
            inviteCodes = (0..<3).map { _ in
                String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement()! })
            }
        }
        isLoading = false
    }

    private func shareInviteCode(_ code: String) {
        let message = "I'm giving you exclusive access to TheDailyPoop — the anonymous gossip app where you pay $1.99 to find out who said what 💩\n\nUse my invite code: \(code)\n\nhttps://thedailypoop.app"
        let ac = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let root = window.rootViewController {
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            top.present(ac, animated: true)
        }
    }
}

#Preview {
    WaitlistView()
        .environmentObject(AuthenticationManager())
}
