import SwiftUI
import MapKit
import CoreLocation

// MARK: - Globe Map View (Hero Screen)
struct GlobeMapView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            distance: 45_000_000
        )
    )
    @State private var selectedDrop: Drop?
    @State private var selectedCluster: ClusteredDrop?
    @State private var drops: [Drop] = []
    @State private var clusteredDrops: [ClusteredDrop] = []
    @State private var hasAnimatedIn = false
    @State private var selectedGroupFilter: Group?
    @State private var groups: [Group] = []

    var body: some View {
        ZStack {
            // Dark globe map
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(clusteredDrops) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        PoopPin(cluster: cluster) {
                            if cluster.drops.count == 1 {
                                selectedDrop = cluster.drops.first
                            } else {
                                selectedCluster = cluster
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .colorScheme(.dark)

            // Overlay UI
            VStack {
                // Top bar: group filter + globe button
                HStack(spacing: 12) {
                    GroupFilterPill(
                        selectedGroup: $selectedGroupFilter,
                        groups: groups,
                        onChanged: { _ in loadDrops() }
                    )

                    Spacer()

                    Button(action: flyToGlobe) {
                        Image(systemName: "globe.americas.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Bottom bar: drop count + center button
                HStack {
                    DropCountBadge(count: drops.count)

                    Spacer()

                    Button(action: centerOnUser) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .onAppear(perform: onMapAppear)
        .sheet(item: $selectedDrop) { drop in
            DropDetailSheet(drop: drop)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedCluster) { cluster in
            ClusterDetailSheet(cluster: cluster) { drop in
                selectedCluster = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedDrop = drop
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_SIGNED_IN"))) { _ in
            loadDrops()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("REFRESH_MAP"))) { _ in
            loadDrops()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CENTER_MAP"))) { notification in
            handleCenterMap(notification)
        }
    }

    // MARK: - Actions

    private func onMapAppear() {
        locationManager.requestLocationPermission()
        loadGroups()
        loadDrops()

        if !hasAnimatedIn {
            hasAnimatedIn = true
            // Epic globe-to-user zoom on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 2.5)) {
                    centerOnUser()
                }
            }
        }
    }

    private func loadGroups() {
        guard let user = authManager.currentUser else { return }
        Task {
            do {
                groups = try await SupabaseManager.shared.fetchMyGroups(userID: user.id)
            } catch {
                print("Failed to load groups: \(error)")
            }
        }
    }

    private func loadDrops() {
        guard let user = authManager.currentUser else { return }
        Task {
            do {
                if let group = selectedGroupFilter {
                    drops = try await SupabaseManager.shared.fetchDrops(groupID: group.id, limit: 500)
                } else {
                    drops = try await SupabaseManager.shared.fetchAllDropsForUser(userID: user.id)
                }
                recluster()
            } catch {
                print("Failed to load drops: \(error)")
            }
        }
    }

    private func recluster() {
        var clusters: [String: [Drop]] = [:]
        for drop in drops {
            guard let key = drop.clusterKey else { continue }
            clusters[key, default: []].append(drop)
        }

        clusteredDrops = clusters.compactMap { (key, clusterDrops) in
            guard let coord = clusterDrops.first?.location else { return nil }
            return ClusteredDrop(
                id: key,
                coordinate: coord,
                drops: clusterDrops.sorted { $0.timestamp > $1.timestamp }
            )
        }
    }

    private func centerOnUser() {
        guard let location = locationManager.location else { return }
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .camera(
                MapCamera(centerCoordinate: location.coordinate, distance: 5000)
            )
        }
    }

    private func flyToGlobe() {
        withAnimation(.easeInOut(duration: 2.0)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                    distance: 45_000_000
                )
            )
        }
    }

    private func handleCenterMap(_ notification: Foundation.Notification) {
        if let coord = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D {
            withAnimation(.easeInOut(duration: 0.8)) {
                cameraPosition = .camera(MapCamera(centerCoordinate: coord, distance: 1000))
            }
            if let drop = notification.userInfo?["drop"] as? Drop {
                if !drops.contains(where: { $0.id == drop.id }) {
                    drops.append(drop)
                    recluster()
                }
            }
        }
    }
}

// MARK: - Clustered Drop Model
struct ClusteredDrop: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let drops: [Drop]

    var count: Int { drops.count }
    var mostRecentDrop: Drop? { drops.first }
}

// MARK: - Poop Pin (bouncy entrance animation)
struct PoopPin: View {
    let cluster: ClusteredDrop
    let onTap: () -> Void
    @State private var appeared = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brown.opacity(0.9), Color.brown],
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)

                Text("💩")
                    .font(.title2)

                // Cluster count badge
                if cluster.count > 1 {
                    Text("\(cluster.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.red))
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                        .offset(x: 16, y: -16)
                }
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double.random(in: 0...0.3))) {
                appeared = true
            }
        }
    }
}

// MARK: - Drop Detail Sheet
struct DropDetailSheet: View {
    let drop: Drop

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.brown.opacity(0.7))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(drop.username.prefix(1)).uppercased())
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(drop.username)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(drop.timestamp.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("💩")
                            .font(.system(size: 36))
                    }

                    if let caption = drop.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let locationName = drop.locationName {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(locationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !drop.reactions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(drop.reactions.keys), id: \.self) { emoji in
                                HStack(spacing: 4) {
                                    Text(emoji)
                                    Text("\(drop.reactions[emoji] ?? 0)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Drop")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Cluster Detail Sheet
struct ClusterDetailSheet: View {
    let cluster: ClusteredDrop
    let onSelectDrop: (Drop) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(cluster.drops) { drop in
                    Button(action: { onSelectDrop(drop) }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.brown.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(drop.username.prefix(1)).uppercased())
                                        .foregroundStyle(.white)
                                        .font(.subheadline.bold())
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(drop.username)
                                    .foregroundStyle(.white)
                                    .fontWeight(.semibold)
                                Text(drop.caption ?? "No caption")
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(drop.timestamp.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("\(cluster.count) drops here")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Group Filter Pill
struct GroupFilterPill: View {
    @Binding var selectedGroup: Group?
    let groups: [Group]
    let onChanged: (Group?) -> Void
    @State private var showingPicker = false

    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack(spacing: 6) {
                Text(selectedGroup?.emoji ?? "🌍")
                Text(selectedGroup?.name ?? "All Groups")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .sheet(isPresented: $showingPicker) {
            GroupPickerSheet(
                selectedGroup: $selectedGroup,
                groups: groups,
                onChanged: onChanged
            )
            .presentationDetents([.medium])
        }
    }
}

struct GroupPickerSheet: View {
    @Binding var selectedGroup: Group?
    let groups: [Group]
    let onChanged: (Group?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedGroup = nil
                    onChanged(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("🌍")
                        Text("All Groups").foregroundStyle(.white)
                        Spacer()
                        if selectedGroup == nil {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(groups) { group in
                    Button(action: {
                        selectedGroup = group
                        onChanged(group)
                        dismiss()
                    }) {
                        HStack {
                            Text(group.emoji)
                            Text(group.name).foregroundStyle(.white)
                            Spacer()
                            if selectedGroup?.id == group.id {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Filter by Group")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Drop Count Badge
struct DropCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("💩")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text("Drops")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    GlobeMapView()
        .environmentObject(AuthenticationManager())
        .environmentObject(LocationManager())
}
