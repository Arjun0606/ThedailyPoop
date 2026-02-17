import SwiftUI

// MARK: - Groups List
struct GroupsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var groups: [Group] = []
    @State private var isLoading = true
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if groups.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Text("💩")
                            .font(.system(size: 80))

                        Text("No Groups Yet")
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text("Create a group and invite your friends to start dropping!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        VStack(spacing: 12) {
                            Button(action: { showingCreate = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Group")
                                }
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)
                            }

                            Button(action: { showingJoin = true }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Join with Code")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groups) { group in
                                GroupRow(
                                    group: group,
                                    onShareInvite: { shareGroupInvite(group) }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingJoin = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(.white)
                    }
                    Button(action: { showingCreate = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateGroupView(onCreated: { group in
                groups.insert(group, at: 0)
            })
        }
        .sheet(isPresented: $showingJoin) {
            JoinGroupView(onJoined: { group in
                groups.insert(group, at: 0)
            })
        }
        .task {
            await loadGroups()
        }
    }

    private func shareGroupInvite(_ group: Group) {
        guard let user = authManager.currentUser else { return }
        let card = GroupInviteCard(group: group, inviterUsername: user.username)
        if let image = ShareCardGenerator.render(card) {
            ShareCardGenerator.share(image: image)
        }
    }

    private func loadGroups() async {
        guard let user = authManager.currentUser else { return }
        do {
            groups = try await SupabaseManager.shared.fetchMyGroups(userID: user.id)
        } catch {
            print("Failed to load groups: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Group Row
struct GroupRow: View {
    let group: Group
    let onShareInvite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(group.emoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(group.members?.count ?? 0) members")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Share invite button
            Button(action: onShareInvite) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: .trailing, spacing: 4) {
                Text(group.inviteCode)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Create Group
struct CreateGroupView: View {
    let onCreated: (Group) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var name = ""
    @State private var emoji = "💩"
    @State private var isCreating = false

    private let emojiOptions = ["💩", "🔥", "👻", "🎯", "💀", "🌮", "🍕", "🎮", "🏠", "❤️", "😈", "🤡"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Selected emoji preview
                    Text(emoji)
                        .font(.system(size: 64))
                        .padding(.top, 20)

                    // Emoji picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojiOptions, id: \.self) { option in
                                Button(action: { emoji = option }) {
                                    Text(option)
                                        .font(.title)
                                        .frame(width: 48, height: 48)
                                        .background(emoji == option ? Color.white.opacity(0.2) : Color.clear)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle().stroke(
                                                emoji == option ? Color.white.opacity(0.5) : Color.clear,
                                                lineWidth: 2
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Name input
                    TextField("Group name", text: $name)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    // Create button
                    Button(action: createGroup) {
                        if isCreating {
                            ProgressView().tint(.black)
                        } else {
                            Text("Create Group")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray : Color.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .disabled(name.isEmpty || isCreating)

                    Spacer()
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingShareInvite) {
            if let group = createdGroup {
                VStack(spacing: 28) {
                    Text("🎉")
                        .font(.system(size: 72))
                        .padding(.top, 20)

                    Text("Group Created!")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    VStack(spacing: 8) {
                        Text("\(group.emoji) \(group.name)")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Code: \(group.inviteCode)")
                            .font(.headline.monospaced())
                            .foregroundStyle(.yellow)
                    }

                    Text("Invite friends to make it lit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(action: {
                        shareCreatedGroup()
                        showingShareInvite = false
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Share Invite")
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

                    Button(action: {
                        showingShareInvite = false
                        dismiss()
                    }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.bottom, 20)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
                .presentationDetents([.medium])
            }
        }
    }

    @State private var createdGroup: Group?
    @State private var showingShareInvite = false

    private func createGroup() {
        guard let user = authManager.currentUser, !name.isEmpty else { return }
        isCreating = true

        Task {
            do {
                let group = try await SupabaseManager.shared.createGroup(
                    name: name,
                    emoji: emoji,
                    createdBy: user.id
                )
                onCreated(group)
                createdGroup = group
                showingShareInvite = true
            } catch {
                print("Failed to create group: \(error)")
            }
            isCreating = false
        }
    }

    private func shareCreatedGroup() {
        guard let group = createdGroup,
              let user = authManager.currentUser else { return }
        let card = GroupInviteCard(group: group, inviterUsername: user.username)
        if let image = ShareCardGenerator.render(card) {
            ShareCardGenerator.share(image: image)
        }
    }
}

// MARK: - Join Group
struct JoinGroupView: View {
    let onJoined: (Group) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var inviteCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("🔗")
                        .font(.system(size: 64))
                        .padding(.top, 20)

                    Text("Enter Invite Code")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Ask your friend for their 6-character group code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    TextField("ABCDEF", text: $inviteCode)
                        .font(.system(.title, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .onChange(of: inviteCode) { _, newValue in
                            inviteCode = String(newValue.prefix(6)).uppercased()
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button(action: joinGroup) {
                        if isJoining {
                            ProgressView().tint(.black)
                        } else {
                            Text("Join Group")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inviteCode.count == 6 ? Color.white : Color.gray)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .disabled(inviteCode.count != 6 || isJoining)

                    Spacer()
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func joinGroup() {
        guard let user = authManager.currentUser else { return }
        isJoining = true
        errorMessage = nil

        Task {
            do {
                let group = try await SupabaseManager.shared.joinGroupByInviteCode(inviteCode, userID: user.id)
                onJoined(group)
                dismiss()
            } catch {
                errorMessage = "Invalid invite code. Check and try again."
            }
            isJoining = false
        }
    }
}

#Preview {
    GroupsView()
        .environmentObject(AuthenticationManager())
}
