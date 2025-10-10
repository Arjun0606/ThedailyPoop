import SwiftUI
import CloudKit

struct AttackActivityFeedView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var activities: [AttackActivity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading && activities.isEmpty {
                    ProgressView("Loading activity...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            loadActivities()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if activities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        Text("No activity yet")
                            .font(.headline)
                        Text("Attack your friends to see the action here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(activities) { activity in
                                ActivityCard(activity: activity)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        loadActivities()
                    }
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if activities.isEmpty {
                loadActivities()
            }
        }
    }
    
    private func loadActivities() {
        guard let currentUserID = authManager.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get list of friend IDs
                let friendIDs = friendsManager.friends.map { $0.id }
                
                // Query AttackActivity for activities involving friends
                let container = CKContainer.default()
                let database = container.publicCloudDatabase
                
                // Create predicates for sender or target being a friend or current user
                var allIDs = friendIDs
                allIDs.append(currentUserID)
                
                let predicate = NSPredicate(format: "senderID IN %@ OR targetUserID IN %@", allIDs, allIDs)
                let query = CKQuery(recordType: AttackActivity.recordType, predicate: predicate)
                query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                
                let results = try await database.records(matching: query, resultsLimit: 50)
                
                let fetchedActivities = results.matchResults.compactMap { _, result -> AttackActivity? in
                    guard case .success(let record) = result else { return nil }
                    return AttackActivity(from: record)
                }
                
                await MainActor.run {
                    self.activities = fetchedActivities
                    self.isLoading = false
                }
            } catch {
                print("Error loading activities: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to load activity feed"
                    self.isLoading = false
                }
            }
        }
    }
}

struct ActivityCard: View {
    let activity: AttackActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: activity.type == .sent ? "paperplane.fill" : "face.smiling.fill")
                .font(.title2)
                .foregroundColor(activity.type == .sent ? .blue : .orange)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(activity.type == .sent ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                if activity.type == .sent {
                    Text("**\(activity.senderUsername)** sent an attack to **\(activity.targetUsername ?? "someone")**")
                        .font(.subheadline)
                } else if activity.type == .reacted {
                    HStack(spacing: 4) {
                        Text("**\(activity.senderUsername)** reacted")
                            .font(.subheadline)
                        if let emoji = activity.reactionEmoji {
                            Text(emoji)
                                .font(.title3)
                        }
                    }
                    
                    if let text = activity.reactionText, !text.isEmpty {
                        Text(text)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Text(timeAgoString(from: activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
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
