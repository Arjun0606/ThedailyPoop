import SwiftUI
import MapKit

struct DemoModeView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Feed Tab
                DemoFeedView()
                    .environmentObject(demoManager)
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet")
                    }
                    .tag(0)
                
                // Friends Tab
                DemoFriendsView()
                    .environmentObject(demoManager)
                    .tabItem {
                        Label("Friends", systemImage: "person.2")
                    }
                    .tag(1)
                
                // Drop Tab (Center)
                Color.clear
                    .tabItem {
                        Label("Drop", systemImage: "plus.circle.fill")
                    }
                    .tag(2)
                
                // Map Tab
                DemoMapView()
                    .environmentObject(demoManager)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(3)
                
                // Profile Tab
                DemoProfileView()
                    .environmentObject(demoManager)
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .tag(4)
            }
            .accentColor(.brown)
            
            // Floating Action Button
            VStack {
                Spacer()
                
                Button(action: {
                    showingDropComposer = true
                }) {
                    Text("💩")
                        .font(.system(size: 40))
                        .frame(width: 70, height: 70)
                        .background(
                            LinearGradient(
                                colors: [Color.brown, Color.brown.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 80)
            }
            
            // Demo Mode Banner
            VStack {
                HStack {
                    Image(systemName: "eye.fill")
                    Text("DEMO MODE - No account needed")
                    Spacer()
                    Button("Exit") {
                        demoManager.exitDemoMode()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue.opacity(0.9))
                
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showingDropComposer) {
            DemoDropComposerView()
                .environmentObject(demoManager)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 2 {
                showingDropComposer = true
                // Reset to previous tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
}

// MARK: - Demo Feed View
struct DemoFeedView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if demoManager.demoDrops.isEmpty {
                    Text("No drops yet!")
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(demoManager.demoDrops) { drop in
                                DemoDropCard(drop: drop)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("💩 Feed")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Demo Friends View
struct DemoFriendsView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    Section("My Friends") {
                        ForEach(demoManager.demoFriends, id: \.id) { friend in
                            HStack {
                                Circle()
                                    .fill(Color.brown.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(Text(String(friend.username.prefix(1)).uppercased()))
                                
                                VStack(alignment: .leading) {
                                    Text("@\(friend.username)")
                                        .fontWeight(.semibold)
                                    Text("\(friend.totalDrops) drops • \(friend.streak) day streak")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Friends")
        }
    }
}

// MARK: - Demo Map View
struct DemoMapView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: demoManager.demoDrops) { drop in
                    MapAnnotation(coordinate: drop.location) {
                        Text("💩")
                            .font(.title)
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("📍 \(demoManager.demoDrops.count) drops in San Francisco")
                        .font(.caption)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Demo Profile View
struct DemoProfileView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.brown.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(Text("D").font(.largeTitle))
                            
                            Text("@\(demoManager.demoUser?.username ?? "demo_reviewer")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("\(demoManager.demoUser?.totalDrops ?? 0)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Drops")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("\(demoManager.demoFriends.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Friends")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Text("\(demoManager.demoUser?.streak ?? 0) 🔥")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Streak")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stats")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                StatRow(label: "Max Drops/Day", value: "\(demoManager.demoUser?.maxDropsInDay ?? 0)")
                                StatRow(label: "Countries", value: "\(demoManager.demoUser?.countriesVisited.count ?? 0)")
                                StatRow(label: "Continents", value: "\(demoManager.demoUser?.continentsVisited.count ?? 0)")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Demo Drop Card
struct DemoDropCard: View {
    let drop: Drop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack {
                Circle()
                    .fill(Color.brown.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text(String(drop.username.prefix(1)).uppercased()))
                
                VStack(alignment: .leading) {
                    Text("@\(drop.username)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("\(drop.city), \(drop.country)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(drop.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Poop emoji
            Text("💩")
                .font(.system(size: 60))
            
            // Rating
            HStack {
                Text("⭐")
                Text("\(drop.rating ?? 5)/10")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            // Caption
            if let caption = drop.caption {
                Text(caption)
                    .foregroundColor(.white)
            }
            
            // Music
            if let title = drop.musicTitle, let artist = drop.musicArtist {
                HStack {
                    Image(systemName: "music.note")
                    Text("\(title) - \(artist)")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Demo Drop Composer
struct DemoDropComposerView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    @Environment(\.dismiss) var dismiss
    @State private var caption = ""
    @State private var rating: Double = 5.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("💩")
                        .font(.system(size: 80))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rate Your Drop")
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("⭐")
                            Slider(value: $rating, in: 1...10, step: 1)
                            Text("\(Int(rating))/10")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    TextField("Add a caption...", text: $caption)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    
                    Button(action: {
                        demoManager.addDemoDrop(caption: caption.isEmpty ? "Test drop" : caption, rating: Int(rating))
                        dismiss()
                    }) {
                        Text("Drop It! 💩")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Text("📍 San Francisco, CA")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationTitle("New Drop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

