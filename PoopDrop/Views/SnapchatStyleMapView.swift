import SwiftUI
import MapKit
import CoreLocation

struct SnapchatStyleMapView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedDrop: Drop?
    @State private var mapTheme: CartoonMapTheme = .snapchatStyle
    @State private var clusteredDrops: [ClusteredDrop] = []
    @State private var selectedCluster: ClusteredDrop? = nil
    @State private var showingClusterSheet: Bool = false
    
    enum CartoonMapTheme: String, CaseIterable {
        case snapchatStyle = "Snapchat Style"
        case darkLuxury = "Dark Luxury" // Pro only
        case cosmicGalaxy = "Cosmic Galaxy" // Pro only
        case toiletPaper = "Toilet Paper Grid" // Pro only
        
        var isPro: Bool {
            switch self {
            case .snapchatStyle:
                return false
            case .darkLuxury, .cosmicGalaxy, .toiletPaper:
                return true
            }
        }
        
        var mapStyle: MapStyle {
            switch self {
            case .snapchatStyle:
                return .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
            case .darkLuxury:
                return .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
            case .cosmicGalaxy:
                return .imagery(elevation: .realistic)
            case .toiletPaper:
                return .hybrid(elevation: .realistic)
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .snapchatStyle: return Color(red: 0.95, green: 0.95, blue: 0.97) // Light Snapchat-like
            case .darkLuxury: return Color.black
            case .cosmicGalaxy: return Color.purple.opacity(0.3)
            case .toiletPaper: return Color.brown.opacity(0.1)
            }
        }
    }
    
    var availableThemes: [CartoonMapTheme] {
        subscriptionManager.isProSubscriber ? CartoonMapTheme.allCases : [.snapchatStyle]
    }
    
    var body: some View {
        ZStack {
            // Custom map background
            mapTheme.backgroundColor.ignoresSafeArea()
            
            // Map with custom styling
            Map(coordinateRegion: $region, annotationItems: clusteredDrops) { cluster in
                MapAnnotation(coordinate: cluster.coordinate) {
                    ClusteredPoopPin(cluster: cluster) {
                        print("🎯 Tapped cluster with \(cluster.drops.count) drops")
                        if cluster.drops.count == 1 {
                            let drop = cluster.drops.first!
                            print("📱 Presenting drop: \(drop.id) - username: \(drop.username)")
                            // Using .sheet(item:) binding - just set selectedDrop and sheet will present automatically
                            selectedDrop = drop
                        } else {
                            selectedCluster = cluster
                            print("📱 Presenting cluster with \(cluster.drops.count) drops")
                            showingClusterSheet = true
                        }
                    }
                }
            }
            .mapStyle(mapTheme.mapStyle)
            .onAppear {
                centerOnUserLocation()
                loadAndClusterDrops()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_SIGNED_IN"))) { _ in
                print("🔄 User signed in, reloading map data")
                loadAndClusterDrops()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("REFRESH_MAP"))) { _ in
                print("🔄 Received REFRESH_MAP notification")
                // Only refresh if we don't have fresh local data
                if clusteredDrops.isEmpty {
                    print("🔄 No local drops, refreshing from CloudKit")
                    loadAndClusterDrops()
                } else {
                    print("🔄 Have local drops, skipping refresh to preserve fresh data")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CENTER_MAP"))) { notification in
                print("🗺️ MapView received CENTER_MAP notification")
                if let coord = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D {
                    print("🎯 Centering map on: \(coord)")
                    withAnimation(.easeInOut(duration: 0.6)) {
                        region = MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    }
                    // If a fresh drop is provided, render it immediately without waiting for CloudKit
                    if let drop = notification.userInfo?["drop"] as? Drop {
                        print("📍 Adding new drop to map immediately: \(drop.id)")
                        let cluster = ClusteredDrop(id: drop.id, coordinate: drop.location ?? coord, drops: [drop])
                        // Prepend if not present
                        if !self.clusteredDrops.contains(where: { $0.id == drop.id }) {
                            self.clusteredDrops.insert(cluster, at: 0)
                            print("✅ Drop added to clusteredDrops. Total drops on map: \(self.clusteredDrops.count)")
                        } else {
                            print("⚠️ Drop already exists on map")
                        }
                    } else {
                        // If we didn't get a new drop, only reload if we have no local pins
                        if self.clusteredDrops.isEmpty {
                            print("🔄 Reloading from CloudKit (no local pins)")
                            loadAndClusterDrops()
                        }
                    }
                } else {
                    print("⚠️ No coordinate in CENTER_MAP notification")
                }
            }
            // Note: onChange removed due to MKCoordinateRegion not conforming to Equatable
            // Can be re-added with custom Equatable implementation if needed
            
            // Snapchat-style overlay elements
            VStack {
                // Top controls
                HStack {
                    // Weather widget (Snapchat-style)
                    WeatherWidget()
                    
                    Spacer()
                    
                    // Removed theme selector - using single map theme
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    // Map stats
                    MapStatsCard(dropsCount: clusteredDrops.reduce(0) { $0 + $1.drops.count })
                    
                    Spacer()
                    
                    // Center on user button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Above tab bar
            }
        }
        .sheet(item: $selectedDrop) { drop in
            DropDetailView(drop: drop)
                .onAppear {
                    print("📱 Presenting DropDetailView for drop: \(drop.id)")
                }
        }
        .sheet(isPresented: $showingClusterSheet) {
            if let cluster = selectedCluster {
                ClusterDetailSheet(cluster: cluster) { drop in
                    selectedDrop = drop
                    // Setting selectedDrop will automatically present the detail sheet via .sheet(item:)
                }
            }
        }
    }
    
    private func centerOnUserLocation() {
        guard let location = locationManager.location else {
            locationManager.requestLocationPermission()
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    private func loadAndClusterDrops() {
        print("🔄 loadAndClusterDrops called")
        Task {
            do {
                // Get visible drops only (not expired)
                let allDrops = try await cloudKitManager.fetchNearbyDrops(
                    coordinate: region.center,
                    radius: 10000 // 10km radius
                )
                
                let visibleDrops = allDrops.filter { $0.isCurrentlyVisible }
                print("🔄 Loaded \(visibleDrops.count) visible drops from CloudKit")
                
                // Cluster drops by location
                let clusters = clusterDrops(visibleDrops)
                print("🔄 Created \(clusters.count) clusters")
                
                await MainActor.run {
                    print("🔄 Updating clusteredDrops from \(self.clusteredDrops.count) to \(clusters.count)")
                    self.clusteredDrops = clusters
                }
            } catch {
                print("Failed to load drops: \(error)")
            }
        }
    }
    
    private func clusterDrops(_ drops: [Drop]) -> [ClusteredDrop] {
        var clusters: [String: [Drop]] = [:]
        
        // Group drops by cluster key
        for drop in drops {
            guard let clusterKey = drop.clusterKey else { continue }
            clusters[clusterKey, default: []].append(drop)
        }
        
        // Convert to ClusteredDrop objects
        return clusters.compactMap { (key, drops) in
            guard let firstDrop = drops.first,
                  let coordinate = firstDrop.location else { return nil }
            
            return ClusteredDrop(
                id: key,
                coordinate: coordinate,
                drops: drops.sorted { $0.timestamp > $1.timestamp } // Most recent first
            )
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
    var hasSponsoredDrops: Bool { drops.contains { $0.isSponsored } }
}

// MARK: - Custom Map Pins
struct ClusteredPoopPin: View {
    let cluster: ClusteredDrop
    let onTap: () -> Void
    @State private var isAnimating = false
    
    private var displayEmoji: String {
        cluster.mostRecentDrop?.displayEmoji ?? "💩"
    }
    
    private var pinColor: Color {
        if cluster.hasSponsoredDrops {
            return .yellow // Pro users get gold pins
        } else {
            return .brown // Free users get brown pins
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Pin background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [pinColor.opacity(0.9), pinColor],
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // Poop emoji or animation
                // Always use plain iOS emoji for pins per request
                Text(displayEmoji)
                    .font(.title2)
                
                // Cluster count badge
                if cluster.count > 1 {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text("\(cluster.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(Color.red)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                )
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .scaleEffect(isAnimating ? 1.2 : 1.0)
        .animation(.bouncy(duration: 0.6), value: isAnimating)
        .onAppear {
            // Animate pins when they appear
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1)) {
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Cluster Detail Sheet
struct ClusterDetailSheet: View {
    let cluster: ClusteredDrop
    let onSelectDrop: (Drop) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Who pooped here?").foregroundColor(.white)) {
                    ForEach(cluster.drops) { drop in
                        Button(action: { onSelectDrop(drop) }) {
                            HStack(spacing: 12) {
                                // Avatar initial
                                Circle()
                                    .fill(Color.brown.opacity(0.8))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Text(String(drop.username.prefix(1)).uppercased())
                                            .foregroundColor(.white)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(drop.username)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    Text(drop.caption ?? "")
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(drop.city ?? "")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            }
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

struct UserLocationPin: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: isPulsing ? 60 : 30, height: isPulsing ? 60 : 30)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
            
            // Inner dot
            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Snapchat-Style Widgets
struct WeatherWidget: View {
    @State private var temperature = "72°"
    @State private var condition = "☀️"
    
    var body: some View {
        HStack(spacing: 8) {
            Text(condition)
                .font(.title3)
            
            Text(temperature)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
}

struct ThemeButton: View {
    @Binding var currentTheme: SnapchatStyleMapView.CartoonMapTheme
    let availableThemes: [SnapchatStyleMapView.CartoonMapTheme]
    @State private var showingThemeSelector = false
    
    var body: some View {
        Button(action: {
            showingThemeSelector = true
        }) {
            Image(systemName: "paintbrush.fill")
                .foregroundColor(.white)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
        }
        .sheet(isPresented: $showingThemeSelector) {
            CartoonMapThemeSelectorView(
                selectedTheme: $currentTheme,
                availableThemes: availableThemes
            )
        }
    }
}

struct MapStatsCard: View {
    let dropsCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(dropsCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Drops Nearby")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text("💩")
                .font(.title3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
}

struct CartoonMapThemeSelectorView: View {
    @Binding var selectedTheme: SnapchatStyleMapView.CartoonMapTheme
    let availableThemes: [SnapchatStyleMapView.CartoonMapTheme]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Choose your map vibe")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(availableThemes, id: \.self) { theme in
                            CartoonThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme
                            ) {
                                selectedTheme = theme
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Map Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CartoonThemeCard: View {
    let theme: SnapchatStyleMapView.CartoonMapTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var themePreview: String {
        switch theme {
        case .snapchatStyle: return "📱"
        case .darkLuxury: return "🌃"
        case .cosmicGalaxy: return "🌌"
        case .toiletPaper: return "🧻"
        }
    }
    
    private var themeDescription: String {
        switch theme {
        case .snapchatStyle: return "Clean & friendly"
        case .darkLuxury: return "Sleek & premium"
        case .cosmicGalaxy: return "Out of this world"
        case .toiletPaper: return "Playful & fun"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Text(themePreview)
                    .font(.system(size: 50))
                
                VStack(spacing: 4) {
                    Text(theme.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(themeDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                if theme.isPro {
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

/*
 RECOMMENDED MAP ASSETS TO PURCHASE:
 
 1. Mapbox Studio (Free tier available):
    - Custom Snapchat-style map themes
    - Cartoon-style map rendering
    - Custom color schemes and styling
    - https://studio.mapbox.com/
 
 2. Apple MapKit Customization (Free):
    - Custom annotations and overlays
    - Styled map configurations
    - Built-in iOS integration
 
 3. IconScout Map Assets:
    - Custom map pin designs
    - Location markers
    - Navigation icons
    - Map overlay elements
 
 4. Alternative: Google Maps Platform
    - Custom map styling (paid)
    - Advanced clustering
    - Street View integration
 
 Note: Apple MapKit is recommended for iOS-only apps as it's free,
 well-integrated, and provides good customization options.
 */

#Preview {
    SnapchatStyleMapView()
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
        .environmentObject(SubscriptionManager())
}
