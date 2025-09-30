import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedDrop: Drop?
    @State private var showingDropDetail = false
    @State private var mapTheme: MapTheme = .standard
    @State private var showingThemeSelector = false
    
    enum MapTheme: String, CaseIterable {
        case standard = "Standard"
        case darkLuxury = "Dark Luxury" // Pro only
        case cosmicGalaxy = "Cosmic Galaxy" // Pro only
        case toiletPaper = "Toilet Paper Grid" // Pro only
        
        var isPro: Bool {
            switch self {
            case .standard:
                return false
            case .darkLuxury, .cosmicGalaxy, .toiletPaper:
                return true
            }
        }
        
        var mapStyle: MapStyle {
            switch self {
            case .standard:
                return .standard(elevation: .realistic)
            case .darkLuxury:
                return .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
            case .cosmicGalaxy:
                return .imagery(elevation: .realistic)
            case .toiletPaper:
                return .hybrid(elevation: .realistic)
            }
        }
    }
    
    var availableThemes: [MapTheme] {
        subscriptionManager.isProSubscriber ? MapTheme.allCases : [.standard]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $region, annotationItems: cloudKitManager.drops.compactMap { (drop: Drop) -> Drop? in
                    guard let location = drop.location else { return nil }
                    return drop
                }) { (drop: Drop) in
                    MapAnnotation(coordinate: drop.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                        PoopPinView(drop: drop) {
                            selectedDrop = drop
                            showingDropDetail = true
                        }
                    }
                }
                .mapStyle(mapTheme.mapStyle)
                
                // Seamless Map Banner Ad Overlay
                VStack {
                    HStack {
                        Spacer()
                        MapBannerAdView()
                            .padding(.top, 10)
                            .padding(.trailing, 16)
                        Spacer()
                            .frame(width: 60) // Space for map controls
                    }
                    Spacer()
                }
                .onAppear {
                    centerOnUserLocation()
                    loadNearbyDrops()
                }
                // Note: onChange removed due to MKCoordinateRegion not conforming to Equatable
                // Can be re-added with custom Equatable implementation if needed
                
                // Controls overlay
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Theme selector (Pro feature)
                            if subscriptionManager.isProSubscriber {
                                Button(action: {
                                    showingThemeSelector = true
                                }) {
                                    Image(systemName: "paintbrush.fill")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(Circle())
                                }
                            }
                            
                            // Center on user location
                            Button(action: centerOnUserLocation) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Map stats
                    MapStatsView(dropsCount: cloudKitManager.drops.count)
                        .padding(.bottom, 100) // Above tab bar
                }
            }
            .navigationTitle("🗺️ Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDropDetail) {
                if let drop = selectedDrop {
                    DropDetailView(drop: drop)
                }
            }
            .sheet(isPresented: $showingThemeSelector) {
                MapThemeSelectorView(
                    selectedTheme: $mapTheme,
                    availableThemes: availableThemes
                )
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
    
    private func loadNearbyDrops() {
        Task {
            do {
                _ = try await cloudKitManager.fetchNearbyDrops(
                    coordinate: region.center,
                    radius: 5000 // 5km radius
                )
            } catch {
                print("Failed to load nearby drops: \(error)")
            }
        }
    }
}

struct PoopPinView: View {
    let drop: Drop
    let onTap: () -> Void
    @State private var isAnimating = false
    
    private var poopEmoji: String {
        drop.skinId ?? "💩"
    }
    
    private var pinColor: Color {
        drop.isSponsored ? .purple : .brown
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Custom poop pin image
                Image("PoopPin")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.bouncy(duration: 0.6), value: isAnimating)
                    .background(
                        Circle()
                            .fill(pinColor.opacity(0.8))
                            .frame(width: 40, height: 40)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                    )
                
                // Pin point
                Triangle()
                    .fill(pinColor)
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
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

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct MapStatsView: View {
    let dropsCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(icon: "💩", value: "\(dropsCount)", label: "Drops")
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            
            StatItem(icon: "📍", value: "5km", label: "Radius")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding(.horizontal, 16)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct DropDetailView: View {
    let drop: Drop
    @Environment(\.dismiss) private var dismiss
    @State private var address: String?
    
    private var coordinatesText: String {
        if let location = drop.location {
            return String(format: "%.4f, %.4f", location.latitude, location.longitude)
        } else {
            return "No location"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Drop card
                    DropCardView(drop: drop)
                    
                    // Location details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location Details")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            LocationDetailRow(
                                icon: "location.fill",
                                title: "Location",
                                value: address ?? "Loading..."
                            )
                            
                            LocationDetailRow(
                                icon: "clock",
                                title: "Dropped",
                                value: formatDate(drop.timestamp)
                            )
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Drop Details")
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
        .onAppear {
            loadAddress()
        }
    }
    
    private func loadAddress() {
        // Use pre-saved location data instead of slow reverse geocoding
        if let city = drop.city, let country = drop.country {
            address = "\(city), \(country)"
        } else if let coordinate = drop.coordinate {
            // Fallback to geocoding only if no saved data
            Task {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                address = await LocationManager().getCityStateCountryFromLocation(location)
            }
        } else {
            address = "Unknown location"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LocationDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MapThemeSelectorView: View {
    @Binding var selectedTheme: MapView.MapTheme
    let availableThemes: [MapView.MapTheme]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose your map style")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(availableThemes, id: \.self) { theme in
                        ThemeCard(
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
            .background(Color.black)
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

struct ThemeCard: View {
    let theme: MapView.MapTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var themePreview: String {
        switch theme {
        case .standard:
            return "🗺️"
        case .darkLuxury:
            return "🌃"
        case .cosmicGalaxy:
            return "🌌"
        case .toiletPaper:
            return "🧻"
        }
    }
    
    private var themeDescription: String {
        switch theme {
        case .standard:
            return "Classic map view"
        case .darkLuxury:
            return "Elegant dark theme"
        case .cosmicGalaxy:
            return "Space-themed view"
        case .toiletPaper:
            return "Fun grid overlay"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Text(themePreview)
                    .font(.system(size: 40))
                
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

#Preview {
    MapView()
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
        .environmentObject(SubscriptionManager())
}
