import SwiftUI
import CloudKit

struct AttackActivityHighlights: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var recentActivities: [AttackActivity] = []
    @State private var isLoading = false
    
    var body: some View {
        if !recentActivities.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Recent Activity")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentActivities.prefix(10)) { activity in
                            CompactActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .task {
                if recentActivities.isEmpty {
                    await loadRecentActivities()
                }
            }
        }
    }
    
    private func loadRecentActivities() async {
        guard let currentUserID = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            // Get list of friend IDs
            let friendIDs = friendsManager.friends.map { $0.id }
            
            // Query AttackActivity for recent activities
            let container = CKContainer.default()
            let database = container.publicCloudDatabase
            
            var allIDs = friendIDs
            allIDs.append(currentUserID)
            
            let predicate = NSPredicate(format: "senderID IN %@ OR targetUserID IN %@", allIDs, allIDs)
            let query = CKQuery(recordType: AttackActivity.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            let results = try await database.records(matching: query, resultsLimit: 10)
            
            let fetchedActivities = results.matchResults.compactMap { _, result -> AttackActivity? in
                guard case .success(let record) = result else { return nil }
                return AttackActivity(from: record)
            }
            
            await MainActor.run {
                self.recentActivities = fetchedActivities
                self.isLoading = false
            }
        } catch {
            print("Error loading recent activities: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct CompactActivityCard: View {
    let activity: AttackActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: activity.type == .sent ? "paperplane.fill" : "face.smiling.fill")
                    .font(.caption)
                    .foregroundColor(activity.type == .sent ? .blue : .orange)
                
                if activity.type == .reacted, let emoji = activity.reactionEmoji {
                    Text(emoji)
                        .font(.title3)
                }
            }
            
            if activity.type == .sent {
                Text("**\(activity.senderUsername)** → **\(activity.targetUsername ?? "?")**")
                    .font(.caption)
                    .lineLimit(1)
            } else {
                Text("**\(activity.senderUsername)** reacted")
                    .font(.caption)
                    .lineLimit(1)
            }
            
            Text(timeAgoString(from: activity.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}
