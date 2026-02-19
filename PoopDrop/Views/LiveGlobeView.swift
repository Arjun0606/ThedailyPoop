import SwiftUI
import SceneKit
import CoreLocation

// MARK: - Location Manager (lightweight, single-use)

class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var latitude: Double?
    @Published var longitude: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            latitude = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

// MARK: - Live Globe Tab

struct LiveGlobeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var locationManager = UserLocationManager()
    @State private var sessions: [ReaderSession] = []
    @State private var recentActivity: [ReaderSession] = []
    @State private var totalReadsToday: Int = 0
    @State private var uniqueReadersToday: Int = 0
    @State private var isLoading = true
    @State private var realtimeTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Stats overlay at top
                StatsOverlayView(sessions: sessions)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // 3D Globe with counter overlay
                ZStack {
                    GlobeSceneView(
                        sessions: sessions,
                        userLatitude: locationManager.latitude,
                        userLongitude: locationManager.longitude
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Counter overlay on globe
                    GlobeCounterOverlay(
                        activeCount: sessions.count,
                        totalReads: totalReadsToday,
                        uniqueReaders: uniqueReadersToday,
                        hasUserLocation: locationManager.latitude != nil
                    )
                }

                // Activity feed at bottom
                ActivityFeedView(activity: recentActivity)
                    .frame(height: 180)
            }
        }
        .task {
            locationManager.requestLocation()
            await loadRecentSessions()
            await loadDailyStats()
            startRealtime()
        }
        .onDisappear {
            realtimeTask?.cancel()
            Task {
                await SupabaseManager.shared.unsubscribeFromReaderSessions()
            }
        }
    }

    private func loadRecentSessions() async {
        do {
            sessions = try await SupabaseManager.shared.fetchRecentReaderSessions(minutes: 5)
            recentActivity = Array(sessions.prefix(10))
        } catch {
            print("Failed to load reader sessions: \(error)")
        }
        isLoading = false
    }

    private func loadDailyStats() async {
        do {
            let stats = try await SupabaseManager.shared.fetchDailyReaderStats()
            uniqueReadersToday = stats.uniqueReaders
            totalReadsToday = stats.totalReads
        } catch {
            print("Failed to load daily stats: \(error)")
        }
    }

    private func startRealtime() {
        realtimeTask = Task {
            await SupabaseManager.shared.subscribeToReaderSessions { newSession in
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.4)) {
                        sessions.append(newSession)
                        recentActivity.insert(newSession, at: 0)
                        if recentActivity.count > 10 {
                            recentActivity.removeLast()
                        }
                        totalReadsToday += 1
                    }

                    // Auto-remove after 60 seconds
                    let sessionId = newSession.id
                    Task {
                        try? await Task.sleep(nanoseconds: 60_000_000_000)
                        await MainActor.run {
                            withAnimation {
                                sessions.removeAll { $0.id == sessionId }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Globe Counter Overlay

struct GlobeCounterOverlay: View {
    let activeCount: Int
    let totalReads: Int
    let uniqueReaders: Int
    let hasUserLocation: Bool

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 24) {
                // Active readers
                VStack(spacing: 2) {
                    Text("\(activeCount)")
                        .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.green)
                    Text("reading now")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 32)

                // Total reads today
                VStack(spacing: 2) {
                    Text("\(totalReads)")
                        .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("reads today")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 1, height: 32)

                // Unique readers
                VStack(spacing: 2) {
                    Text("\(uniqueReaders)")
                        .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.orange)
                    Text("readers")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial.opacity(0.7))
            .cornerRadius(16)

            if hasUserLocation {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text("You're on the globe")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Stats Overlay

struct StatsOverlayView: View {
    let sessions: [ReaderSession]

    private var countryCounts: [(code: String, name: String, count: Int)] {
        var counts: [String: (name: String, count: Int)] = [:]
        for session in sessions {
            let code = session.countryCode ?? "??"
            let name = session.countryName ?? "Unknown"
            counts[code, default: (name: name, count: 0)].count += 1
        }
        return counts
            .map { (code: $0.key, name: $0.value.name, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Pulsing green dot
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.4), lineWidth: 2)
                            .scaleEffect(1.8)
                    )

                Text("\(sessions.count) reading right now")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("LIVE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                    .tracking(1)
            }

            if !countryCounts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(countryCounts.prefix(8), id: \.code) { country in
                            HStack(spacing: 4) {
                                Text(countryFlag(country.code))
                                    .font(.caption)
                                Text("\(country.code)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("(\(country.count))")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }

    private func countryFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        return String(code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { Character($0) })
    }
}

// MARK: - SceneKit Globe

struct GlobeSceneView: UIViewRepresentable {
    let sessions: [ReaderSession]
    let userLatitude: Double?
    let userLongitude: Double?

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false

        let scene = SCNScene()
        sceneView.scene = scene

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 3.5)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 1.0, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Globe sphere
        let globe = createGlobe()
        globe.name = "globe"
        scene.rootNode.addChildNode(globe)

        // Auto-rotate
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 30)
        globe.runAction(SCNAction.repeatForever(rotation))

        // Atmosphere glow
        let atmosphere = createAtmosphere()
        scene.rootNode.addChildNode(atmosphere)

        context.coordinator.sceneView = sceneView
        context.coordinator.globeNode = globe

        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        context.coordinator.updateDots(sessions: sessions)
        context.coordinator.updateUserDot(latitude: userLatitude, longitude: userLongitude)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func createGlobe() -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 72

        let material = SCNMaterial()

        if let earthTexture = UIImage(named: "earth_dark") {
            material.diffuse.contents = earthTexture
        } else {
            material.diffuse.contents = UIColor(red: 0.08, green: 0.14, blue: 0.28, alpha: 1.0)
        }
        material.lightingModel = .constant

        sphere.materials = [material]
        return SCNNode(geometry: sphere)
    }

    private func createAtmosphere() -> SCNNode {
        let sphere = SCNSphere(radius: 1.04)
        sphere.segmentCount = 48

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.03)
        material.emission.contents = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.02)
        material.isDoubleSided = true
        material.transparency = 0.4
        sphere.materials = [material]

        return SCNNode(geometry: sphere)
    }

    // MARK: - Coordinator

    class Coordinator {
        var sceneView: SCNView?
        var globeNode: SCNNode?
        var activeDots: [String: SCNNode] = [:]
        var userDotNode: SCNNode?

        // MARK: Reader Dots (Heatmap Style)

        func updateDots(sessions: [ReaderSession]) {
            guard let globe = globeNode else { return }

            let sessionIDs = Set(sessions.map { $0.id })

            // Remove dots no longer in sessions
            for (id, node) in activeDots {
                if !sessionIDs.contains(id) {
                    node.runAction(SCNAction.sequence([
                        SCNAction.fadeOut(duration: 0.5),
                        SCNAction.removeFromParentNode()
                    ]))
                    activeDots.removeValue(forKey: id)
                }
            }

            // Add new dots
            for session in sessions {
                if activeDots[session.id] == nil {
                    let dot = createHeatmapDot(
                        latitude: session.latitude,
                        longitude: session.longitude,
                        style: .reader
                    )
                    dot.name = session.id
                    globe.addChildNode(dot)
                    activeDots[session.id] = dot

                    // Animate in
                    dot.scale = SCNVector3(0, 0, 0)
                    dot.opacity = 0
                    dot.runAction(SCNAction.group([
                        SCNAction.scale(to: 1.0, duration: 0.4),
                        SCNAction.fadeIn(duration: 0.4)
                    ]))

                    // Pulse animation
                    let pulse = SCNAction.sequence([
                        SCNAction.scale(to: 1.3, duration: 0.8),
                        SCNAction.scale(to: 1.0, duration: 0.8)
                    ])
                    dot.runAction(SCNAction.repeatForever(pulse))
                }
            }
        }

        // MARK: User "You Are Here" Dot

        func updateUserDot(latitude: Double?, longitude: Double?) {
            guard let globe = globeNode, let lat = latitude, let lng = longitude else { return }

            // Only create once
            if userDotNode != nil { return }

            let dot = createHeatmapDot(latitude: lat, longitude: lng, style: .userSelf)
            dot.name = "user_self"
            globe.addChildNode(dot)
            userDotNode = dot

            // Animate in
            dot.scale = SCNVector3(0, 0, 0)
            dot.opacity = 0
            dot.runAction(SCNAction.group([
                SCNAction.scale(to: 1.0, duration: 0.6),
                SCNAction.fadeIn(duration: 0.6)
            ]))

            // Slow breathe animation
            let breathe = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 1.2),
                SCNAction.scale(to: 1.0, duration: 1.2)
            ])
            dot.runAction(SCNAction.repeatForever(breathe))
        }

        // MARK: Heatmap Dot Factory

        enum DotStyle {
            case reader   // green heatmap
            case userSelf // blue "you" marker
        }

        private func createHeatmapDot(latitude: Double, longitude: Double, style: DotStyle) -> SCNNode {
            let container = SCNNode()

            // Position on globe surface
            let latRad = latitude * .pi / 180
            let lngRad = longitude * .pi / 180
            let r: Double = 1.02

            let x = r * cos(latRad) * sin(lngRad)
            let y = r * sin(latRad)
            let z = r * cos(latRad) * cos(lngRad)

            container.position = SCNVector3(Float(x), Float(y), Float(z))

            let baseColor: UIColor
            switch style {
            case .reader:
                baseColor = UIColor(red: 0.2, green: 0.95, blue: 0.5, alpha: 1.0)
            case .userSelf:
                baseColor = UIColor(red: 0.3, green: 0.55, blue: 1.0, alpha: 1.0)
            }

            // Layer 1: Inner core (bright white center)
            let core = SCNSphere(radius: 0.012)
            let coreMat = SCNMaterial()
            coreMat.diffuse.contents = UIColor.white
            coreMat.emission.contents = baseColor
            coreMat.lightingModel = .constant
            core.materials = [coreMat]
            container.addChildNode(SCNNode(geometry: core))

            // Layer 2: Mid glow
            let mid = SCNSphere(radius: 0.035)
            mid.segmentCount = 24
            let midMat = SCNMaterial()
            midMat.diffuse.contents = baseColor.withAlphaComponent(0.45)
            midMat.emission.contents = baseColor.withAlphaComponent(0.35)
            midMat.lightingModel = .constant
            midMat.isDoubleSided = true
            mid.materials = [midMat]
            container.addChildNode(SCNNode(geometry: mid))

            // Layer 3: Outer heatmap glow (large, faint)
            let outerRadius: CGFloat = style == .userSelf ? 0.10 : 0.07
            let outer = SCNSphere(radius: outerRadius)
            outer.segmentCount = 24
            let outerMat = SCNMaterial()
            outerMat.diffuse.contents = baseColor.withAlphaComponent(0.12)
            outerMat.emission.contents = baseColor.withAlphaComponent(0.08)
            outerMat.lightingModel = .constant
            outerMat.isDoubleSided = true
            outer.materials = [outerMat]
            container.addChildNode(SCNNode(geometry: outer))

            // Layer 4: Heatmap spread (very large, very faint — overlaps create density)
            let spread = SCNSphere(radius: style == .userSelf ? 0.18 : 0.14)
            spread.segmentCount = 16
            let spreadMat = SCNMaterial()
            spreadMat.diffuse.contents = baseColor.withAlphaComponent(0.04)
            spreadMat.emission.contents = baseColor.withAlphaComponent(0.03)
            spreadMat.lightingModel = .constant
            spreadMat.isDoubleSided = true
            spread.materials = [spreadMat]
            container.addChildNode(SCNNode(geometry: spread))

            // Ring around "you" dot for distinction
            if style == .userSelf {
                let ring = SCNTorus(ringRadius: 0.05, pipeRadius: 0.003)
                let ringMat = SCNMaterial()
                ringMat.diffuse.contents = baseColor.withAlphaComponent(0.3)
                ringMat.emission.contents = baseColor.withAlphaComponent(0.2)
                ringMat.lightingModel = .constant
                ring.materials = [ringMat]
                let ringNode = SCNNode(geometry: ring)
                ringNode.look(at: SCNVector3(0, 0, 0))
                container.addChildNode(ringNode)
            }

            return container
        }
    }
}

// MARK: - Activity Feed

struct ActivityFeedView: View {
    let activity: [ReaderSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("LIVE ACTIVITY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if activity.isEmpty {
                VStack(spacing: 8) {
                    Text("Waiting for readers...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(activity) { session in
                            ActivityRow(session: session)
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.05))
    }
}

struct ActivityRow: View {
    let session: ReaderSession

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.green.opacity(0.6))
                .frame(width: 6, height: 6)

            Text(displayText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Spacer()

            Text(timeAgo)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var displayText: String {
        let name = session.username ?? "someone"
        let flag = session.countryCode.map { countryFlag($0) } ?? ""
        let country = session.countryCode ?? ""
        let headline = session.storyHeadline ?? "a story"
        let truncatedHeadline = headline.count > 35
            ? String(headline.prefix(35)) + "..."
            : headline
        return "\(flag) @\(name) from \(country) read \"\(truncatedHeadline)\""
    }

    private var timeAgo: String {
        let seconds = Date().timeIntervalSince(session.createdAt)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        return "\(Int(seconds / 3600))h ago"
    }

    private func countryFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        return String(code.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { Character($0) })
    }
}

#Preview {
    LiveGlobeView()
        .environmentObject(AuthenticationManager())
}
