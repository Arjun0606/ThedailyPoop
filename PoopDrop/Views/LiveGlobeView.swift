import SwiftUI
import SceneKit

// MARK: - Live Globe Tab
struct LiveGlobeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var sessions: [ReaderSession] = []
    @State private var recentActivity: [ReaderSession] = []
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

                // 3D Globe
                GlobeSceneView(sessions: sessions)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Activity feed at bottom
                ActivityFeedView(activity: recentActivity)
                    .frame(height: 180)
            }
        }
        .task {
            await loadRecentSessions()
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
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

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
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)

        // Directional light for subtle highlight
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.2, alpha: 1.0)
        directionalLight.position = SCNVector3(2, 2, 3)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)

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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func createGlobe() -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 64

        let material = SCNMaterial()
        // Dark navy globe base
        material.diffuse.contents = UIColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0)
        material.specular.contents = UIColor(white: 0.15, alpha: 1.0)
        material.shininess = 0.3

        // If we have the earth texture, use it
        if let earthTexture = UIImage(named: "earth_dark") {
            material.diffuse.contents = earthTexture
        }

        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)

        // Add continent outlines as a wireframe overlay
        let wireframe = SCNSphere(radius: 1.002)
        wireframe.segmentCount = 32
        let wireMaterial = SCNMaterial()
        wireMaterial.diffuse.contents = UIColor(white: 0.15, alpha: 0.3)
        wireMaterial.fillMode = .lines
        wireframe.materials = [wireMaterial]
        let wireNode = SCNNode(geometry: wireframe)
        wireNode.name = "wireframe"
        node.addChildNode(wireNode)

        // Grid lines for longitude/latitude feel
        addGridLines(to: node)

        return node
    }

    private func addGridLines(to node: SCNNode) {
        // Add subtle latitude lines
        for lat in stride(from: -60, through: 60, by: 30) {
            let radius = cos(Double(lat) * .pi / 180)
            let y = sin(Double(lat) * .pi / 180)

            let ring = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: 0.002)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(white: 0.2, alpha: 0.15)
            ring.materials = [material]

            let ringNode = SCNNode(geometry: ring)
            ringNode.position.y = Float(y)
            node.addChildNode(ringNode)
        }
    }

    private func createAtmosphere() -> SCNNode {
        let sphere = SCNSphere(radius: 1.05)
        sphere.segmentCount = 48

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.04)
        material.isDoubleSided = true
        material.transparency = 0.3
        sphere.materials = [material]

        return SCNNode(geometry: sphere)
    }

    // MARK: - Coordinator
    class Coordinator {
        var sceneView: SCNView?
        var globeNode: SCNNode?
        var activeDots: [String: SCNNode] = [:]

        func updateDots(sessions: [ReaderSession]) {
            guard let globe = globeNode else { return }

            let sessionIDs = Set(sessions.map { $0.id })

            // Remove dots that are no longer in sessions
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
                    let dot = createDot(
                        latitude: session.latitude,
                        longitude: session.longitude
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

        private func createDot(latitude: Double, longitude: Double) -> SCNNode {
            let dotGeometry = SCNSphere(radius: 0.018)

            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 1.0)
            material.emission.contents = UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 0.8)
            dotGeometry.materials = [material]

            let dotNode = SCNNode(geometry: dotGeometry)

            // Convert lat/lng to 3D position on sphere surface
            let latRad = latitude * .pi / 180
            let lngRad = longitude * .pi / 180
            let r: Double = 1.02 // slightly above globe surface

            let x = r * cos(latRad) * cos(lngRad)
            let y = r * sin(latRad)
            let z = r * cos(latRad) * sin(-lngRad) // negate for correct orientation

            dotNode.position = SCNVector3(Float(x), Float(y), Float(z))

            // Add a glow ring around the dot
            let ring = SCNTorus(ringRadius: 0.03, pipeRadius: 0.003)
            let ringMaterial = SCNMaterial()
            ringMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 0.3)
            ringMaterial.emission.contents = UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 0.2)
            ring.materials = [ringMaterial]

            let ringNode = SCNNode(geometry: ring)
            // Orient ring to face outward from globe center
            ringNode.look(at: SCNVector3(0, 0, 0))
            dotNode.addChildNode(ringNode)

            return dotNode
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
