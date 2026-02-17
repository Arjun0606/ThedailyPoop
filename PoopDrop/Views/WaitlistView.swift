import SwiftUI

// MARK: - Waitlist / School Unlock System
// Gas-style FOMO: "Your school isn't unlocked yet. Invite 5 friends to unlock."
// Drives organic installs through artificial scarcity.

struct WaitlistView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var schoolName = ""
    @State private var position: Int = 0
    @State private var totalWaiting: Int = 0
    @State private var invitesSent: Int = 0
    @State private var requiredInvites = 5
    @State private var isRegistering = false
    @State private var isRegistered = false
    @State private var showingShareInvite = false

    private var progress: Double {
        min(Double(invitesSent) / Double(requiredInvites), 1.0)
    }

    private var isUnlocked: Bool {
        invitesSent >= requiredInvites
    }

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

                        Text("is coming to your school")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    if !isRegistered {
                        // School input
                        schoolInputSection
                    } else if isUnlocked {
                        // Unlocked!
                        unlockedSection
                    } else {
                        // Waitlist position + invite progress
                        waitlistSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingShareInvite) {
            WaitlistShareSheet(
                schoolName: schoolName,
                position: position,
                onShared: {
                    invitesSent += 1
                    showingShareInvite = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - School Input

    private var schoolInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your school?")
                    .font(.headline)
                    .foregroundStyle(.white)

                TextField("School name", text: $schoolName)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.words)
            }

            Button(action: joinWaitlist) {
                if isRegistering {
                    ProgressView().tint(.black)
                } else {
                    Text("Join the Waitlist")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(schoolName.isEmpty ? Color.gray : Color.yellow)
            .cornerRadius(14)
            .disabled(schoolName.isEmpty || isRegistering)

            // Social proof
            VStack(spacing: 8) {
                HStack(spacing: -8) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.purple.opacity(Double(5 - i) / 5.0))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(["😂", "💀", "🔥", "👻", "😈"][i])
                                    .font(.caption)
                            )
                    }
                }

                Text("2,847 students already waiting")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Waitlist Section

    private var waitlistSection: some View {
        VStack(spacing: 28) {
            // Position card
            VStack(spacing: 12) {
                Text("Your Position")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(2)

                Text("#\(position)")
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)

                Text("at \(schoolName)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Text("\(totalWaiting) students waiting")
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

            // Unlock progress
            VStack(spacing: 16) {
                Text("Skip the line")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Invite \(requiredInvites) friends to unlock instantly")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress)
                                .animation(.spring(response: 0.5), value: progress)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("\(invitesSent)/\(requiredInvites) invited")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                        Spacer()
                        if invitesSent > 0 {
                            Text("\(requiredInvites - invitesSent) more to go!")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                // Invite button
                Button(action: { showingShareInvite = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                        Text("Invite a Friend")
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
                    Text("Live Activity")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }

                VStack(spacing: 8) {
                    FOMORow(emoji: "🔥", text: "Jake from Lincoln High just joined", time: "2m ago")
                    FOMORow(emoji: "💀", text: "Sarah unlocked UCLA!", time: "5m ago")
                    FOMORow(emoji: "😈", text: "3 people from \(schoolName) joined", time: "12m ago")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }

    // MARK: - Unlocked Section

    private var unlockedSection: some View {
        VStack(spacing: 28) {
            Text("🎉")
                .font(.system(size: 80))

            Text("\(schoolName) is UNLOCKED!")
                .font(.title.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("You skipped the line. You're in.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Button(action: {
                // Mark waitlist as completed → transition to main app
                UserDefaults.standard.set(true, forKey: "waitlistCompleted")
                NotificationCenter.default.post(
                    name: Notification.Name("WAITLIST_COMPLETED"),
                    object: nil
                )
            }) {
                HStack(spacing: 10) {
                    Text("💩")
                    Text("Start Dropping")
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
    }

    // MARK: - Actions

    private func joinWaitlist() {
        guard let user = authManager.currentUser, !schoolName.isEmpty else { return }
        isRegistering = true

        Task {
            do {
                let result = try await SupabaseManager.shared.joinWaitlist(
                    userID: user.id,
                    schoolName: schoolName
                )
                position = result.position
                totalWaiting = result.totalWaiting
                isRegistered = true
            } catch {
                // Fallback: generate a fake position for demo
                position = Int.random(in: 40...200)
                totalWaiting = Int.random(in: 200...500)
                isRegistered = true
            }
            isRegistering = false
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

// MARK: - Waitlist Share Sheet

struct WaitlistShareSheet: View {
    let schoolName: String
    let position: Int
    let onShared: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("📲")
                    .font(.system(size: 56))
                    .padding(.top, 20)

                Text("Send to a friend")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("When they join, you both move up the waitlist")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    let message = "Join me on TheDailyPoop! The anonymous gossip app is coming to \(schoolName). I'm #\(position) on the waitlist 💩🔥\n\nDownload: https://thedailypoop.app"
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
                        Text("Share Invite Link")
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

#Preview {
    WaitlistView()
        .environmentObject(AuthenticationManager())
}
