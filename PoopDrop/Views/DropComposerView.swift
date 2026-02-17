import SwiftUI
import CoreLocation

struct DropComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var locationManager: LocationManager

    @State private var caption = ""
    @State private var isDropping = false
    @State private var showingLocationError = false
    @State private var currentLocation: CLLocation?
    @State private var selectedGroup: Group?
    @State private var groups: [Group] = []

    private let maxChars = 280

    var canDrop: Bool {
        currentLocation != nil
        && !isDropping
        && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && selectedGroup != nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Location
                        if let location = currentLocation {
                            LocationInfoView(location: location)
                        } else {
                            LocationLoadingView()
                        }

                        // Group picker
                        GroupDropdownSection(
                            selectedGroup: $selectedGroup,
                            groups: groups
                        )

                        // Caption
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Caption")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(caption.count)/\(maxChars)")
                                    .font(.caption)
                                    .foregroundStyle(caption.count > maxChars ? .red : .secondary)
                            }

                            TextField("What's happening?", text: $caption, axis: .vertical)
                                .lineLimit(4)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundStyle(.white)
                                .onChange(of: caption) { _, newValue in
                                    if newValue.count > maxChars {
                                        caption = String(newValue.prefix(maxChars))
                                    }
                                }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // Drop button
                VStack {
                    Spacer()
                    Button(action: createDrop) {
                        HStack {
                            if isDropping {
                                ProgressView().tint(.black)
                                Text("Dropping...")
                            } else {
                                Text("💩").font(.title2)
                                Text("Drop It!").fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canDrop ? Color.white : Color.gray)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                    }
                    .disabled(!canDrop)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Drop a Poop 💩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            getCurrentLocation()
            loadGroups()
        }
        .alert("Location Required", isPresented: $showingLocationError) {
            Button("OK") { dismiss() }
        } message: {
            Text("TheDailyPoop needs location access to pin your drops on the map.")
        }
    }

    private func getCurrentLocation() {
        Task {
            do {
                currentLocation = try await locationManager.getCurrentLocation()
            } catch {
                showingLocationError = true
            }
        }
    }

    private func loadGroups() {
        guard let user = authManager.currentUser else { return }
        Task {
            do {
                groups = try await SupabaseManager.shared.fetchMyGroups(userID: user.id)
                if selectedGroup == nil { selectedGroup = groups.first }
            } catch {
                print("Failed to load groups: \(error)")
            }
        }
    }

    private func createDrop() {
        guard let user = authManager.currentUser,
              let location = currentLocation,
              let group = selectedGroup else { return }

        isDropping = true

        Task {
            // Reverse geocode
            var locationName: String?
            let geocoder = CLGeocoder()
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                locationName = [placemark.name, placemark.locality]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            }

            let drop = Drop(
                userID: user.id,
                username: user.username,
                location: location.coordinate,
                locationName: locationName,
                caption: caption.isEmpty ? nil : caption,
                groupID: group.id
            )

            do {
                try await SupabaseManager.shared.saveDrop(drop)

                // Update local user stats
                var updatedUser = user
                updatedUser.totalDrops += 1
                try? await SupabaseManager.shared.saveUser(updatedUser)

                await MainActor.run {
                    authManager.currentUser = updatedUser
                    isDropping = false
                    dismiss()
                    NotificationCenter.default.post(
                        name: Notification.Name("DID_CREATE_DROP"),
                        object: nil,
                        userInfo: ["drop": drop]
                    )
                    NotificationCenter.default.post(
                        name: Notification.Name("USER_STATS_UPDATED"),
                        object: nil
                    )
                }
            } catch {
                await MainActor.run {
                    isDropping = false
                    // Show on map even if save failed (optimistic)
                    dismiss()
                    NotificationCenter.default.post(
                        name: Notification.Name("DID_CREATE_DROP"),
                        object: nil,
                        userInfo: ["drop": drop]
                    )
                }
            }
        }
    }
}

// MARK: - Group Dropdown
struct GroupDropdownSection: View {
    @Binding var selectedGroup: Group?
    let groups: [Group]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drop in Group")
                .font(.headline)
                .foregroundStyle(.white)

            if groups.isEmpty {
                Text("Create a group first to start dropping!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(groups) { group in
                            Button(action: { selectedGroup = group }) {
                                HStack(spacing: 6) {
                                    Text(group.emoji)
                                    Text(group.name)
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(selectedGroup?.id == group.id ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedGroup?.id == group.id ? Color.white : Color.white.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Location Info
struct LocationInfoView: View {
    let location: CLLocation
    @State private var address: String?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.green)
                Text("Current Location")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            if let address = address {
                HStack {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            Task { address = await LocationManager().getAddressFromLocation(location) }
        }
    }
}

struct LocationLoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Getting your location...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    DropComposerView()
        .environmentObject(AuthenticationManager())
        .environmentObject(LocationManager())
}
