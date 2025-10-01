import SwiftUI
import CoreLocation

struct DropCardView: View {
    let drop: Drop
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var address: String
    @State private var userAvatar: UIImage? = nil
    @State private var showingShareSheet = false
    @State private var showingReportSheet = false
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: drop.timestamp, relativeTo: Date())
    }
    
    private var poopEmoji: String {
        return drop.displayEmoji
    }
    
    private var isSponsored: Bool {
        drop.isSponsored
    }
    
    init(drop: Drop) {
        self.drop = drop
        // Initialize address immediately to avoid loading states
        if let city = drop.city, let country = drop.country {
            self._address = State(initialValue: "\(city), \(country)")
        } else if let coord = drop.location {
            self._address = State(initialValue: "Lat: \(String(format: "%.4f", coord.latitude)), Lng: \(String(format: "%.4f", coord.longitude))")
        } else {
            self._address = State(initialValue: "Unknown location")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Profile picture with avatar support
                if let avatar = userAvatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brown.opacity(0.7), Color.brown],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(drop.username.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(drop.username)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if isSponsored {
                            SponsoredBadge()
                        }
                        
                        if subscriptionManager.isProSubscriber && !isSponsored {
                            ProBadge()
                        }
                    }
                    
                    HStack(spacing: 4) {
                        if !drop.isNoPoop {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        } else {
                            Text("No location (no poop)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // More options menu
                Menu {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    if !isSponsored {
                        Button(role: .destructive, action: {
                            showingReportSheet = true
                        }) {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.title3)
                }
            }
            
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Poop emoji with animation
                HStack {
                    Text(poopEmoji)
                        .font(.system(size: 48))
                        .scaleEffect(1.0)
                        .animation(.bouncy(duration: 0.6), value: poopEmoji)
                    
                    Spacer()
                }
                
                // NEW: Rating display
                if let rating = drop.rating {
                    HStack(spacing: 8) {
                        Text("⭐")
                            .font(.title3)
                        Text("\(rating)/10")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        Text(drop.ratingDescription)
                            .font(.subheadline)
                            .foregroundColor(.orange.opacity(0.9))
                    }
                    .padding(.vertical, 8)
                }
                
                // Caption
                if let caption = drop.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // NEW: Music display
                if let musicTitle = drop.musicTitle, let musicURL = drop.musicURL {
                    Button(action: {
                        if let url = URL(string: musicURL) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Album cover art or music icon
                            if let coverArtURL = drop.musicCoverArt, let url = URL(string: coverArtURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.green.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.6)
                                        )
                                }
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                            } else {
                                Image(systemName: "music.note")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                    .frame(width: 50, height: 50)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("🎵 Listening to")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text(musicTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                if let artist = drop.musicArtist {
                                    Text(artist)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Sponsored content
                if isSponsored {
                    SponsoredContentView(drop: drop)
                }
            }
            
            // Reactions
            ReactionBarView(drop: drop)
            
            // Share sheet
            if showingShareSheet {
                ShareSheetView(drop: drop, isPresented: $showingShareSheet)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isSponsored 
                    ? LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSponsored ? Color.purple.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            loadUserAvatar()
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportView(drop: drop)
        }
    }
    
    private func loadAddress() {
        // Only load address for drops with actual locations
        guard let coordinate = drop.coordinate else { return }
        
        Task {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            // Get only city, state, country for privacy
            address = await LocationManager().getCityStateCountryFromLocation(location) ?? "Unknown location"
        }
    }
    
    private func loadUserAvatar() {
        Task {
            do {
                if let user = try await CloudKitManager.shared.fetchUser(id: drop.userID),
                   let avatarURL = user.avatarURL {
                    
                    print("🖼️ Loading avatar for \(drop.username) from: \(avatarURL)")
                    
                    let data = try Data(contentsOf: avatarURL)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.userAvatar = image
                            print("✅ Avatar loaded successfully for \(drop.username)")
                        }
                    } else {
                        print("❌ Failed to create UIImage from data for \(drop.username)")
                    }
                } else {
                    print("⚠️ No avatar URL found for user \(drop.username)")
                }
            } catch {
                print("❌ Failed to load user avatar for \(drop.username): \(error)")
                // Will show initial instead
            }
        }
    }
}

struct SponsoredBadge: View {
    var body: some View {
        Text("SPONSORED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.yellow)
            .cornerRadius(4)
    }
}

struct SponsoredContentView: View {
    let drop: Drop
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var campaign: SponsorCampaign?
    
    var body: some View {
        if let campaign = campaign {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎯")
                        .font(.title3)
                    
                    Text("Special Offer from \(campaign.brandName)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                if let discount = campaign.actionPayload["discount"] {
                    Text(discount)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                if let code = campaign.actionPayload["code"] {
                    HStack {
                        Text("Code: \(code)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(6)
                        
                        Button("Copy") {
                            UIPasteboard.general.string = code
                        }
                        .font(.caption)
                        .foregroundColor(.yellow)
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func loadCampaign() {
        guard let campaignId = drop.sponsorCampaignID else { return }
        
        // Find campaign in CloudKit manager's campaigns
        campaign = cloudKitManager.sponsorCampaigns.first { $0.id == campaignId }
    }
}

struct ShareSheetView: View {
    let drop: Drop
    @Binding var isPresented: Bool
    
    var shareText: String {
        var text = "Check out this poop drop on Poop Drop! 💩"
        
        if let caption = drop.caption, !caption.isEmpty {
            text += "\n\n\"\(caption)\""
        }
        
        text += "\n\nDrop by \(drop.username)"
        text += "\n\nDownload Poop Drop: [App Store Link]"
        
        return text
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share this Drop")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ShareButton(
                    title: "Share to TikTok",
                    icon: "music.note",
                    color: .black,
                    action: shareToTikTok
                )
                
                ShareButton(
                    title: "Share to Instagram",
                    icon: "camera",
                    color: .purple,
                    action: shareToInstagram
                )
                
                ShareButton(
                    title: "Copy Link",
                    icon: "link",
                    color: .blue,
                    action: copyLink
                )
                
                ShareButton(
                    title: "More Options",
                    icon: "square.and.arrow.up",
                    color: .gray,
                    action: shareMore
                )
            }
            
            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.black)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private func shareToTikTok() {
        // Implement TikTok sharing
        isPresented = false
    }
    
    private func shareToInstagram() {
        // Implement Instagram sharing
        isPresented = false
    }
    
    private func copyLink() {
        UIPasteboard.general.string = "https://poopdrop.app/drop/\(drop.id)"
        isPresented = false
    }
    
    private func shareMore() {
        // Present system share sheet
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        isPresented = false
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ReportView: View {
    let drop: Drop
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = ""
    @State private var customReason = ""
    @State private var isSubmitting = false
    
    private let reportReasons = [
        "Inappropriate content",
        "Spam",
        "Harassment",
        "False information",
        "Copyright violation",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Why are you reporting this drop?")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    ForEach(reportReasons, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedReason == reason ? .blue : .white.opacity(0.6))
                                
                                Text(reason)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                
                if selectedReason == "Other" {
                    TextField("Please specify...", text: $customReason, axis: .vertical)
                        .lineLimit(3)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: submitReport) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Report")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedReason.isEmpty ? Color.gray : Color.red)
                    .cornerRadius(12)
                }
                .disabled(selectedReason.isEmpty || isSubmitting)
            }
            .padding(20)
            .background(Color.black)
            .navigationTitle("Report Drop")
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
        .preferredColorScheme(.dark)
    }
    
    private func submitReport() {
        isSubmitting = true
        
        // Simulate report submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            DropCardView(drop: Drop.sampleDrop)
            DropCardView(drop: Drop.sponsoredDrop)
        }
        .padding()
    }
    .background(Color.black)
    .environmentObject(SubscriptionManager())
    .environmentObject(CloudKitManager())
}
