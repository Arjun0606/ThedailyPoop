import SwiftUI
import ContactsUI

struct ExternalFartAttackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var fartAttackManager = FartAttackManager.shared
    
    @State private var recipientName = ""
    @State private var recipientIdentifier = "" // Phone or email
    @State private var isCreatingAttack = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    var attacksAvailable: Int {
        fartAttackManager.inventory?.availableAttacks ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("💨")
                                .font(.system(size: 100))
                            
                            Text("Send Fart Attack")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Text("Prank anyone, even if they don't have the app!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Attacks available
                        HStack(spacing: 10) {
                            Text("Attacks available:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(attacksAvailable)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Input fields
                        VStack(spacing: 16) {
                            // Recipient name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recipient Name")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("Enter their name", text: $recipientName)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .autocapitalization(.words)
                            }
                            
                            // Recipient identifier (phone or email)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number or Email (for cooldown)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("Optional - prevents spam", text: $recipientIdentifier)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            Text("This info is hashed and never stored - it's only used for 24hr cooldown tracking")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        // How it works
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How It Works:")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            InfoRow(icon: "1.circle.fill", text: "You send them a link via text, WhatsApp, etc.")
                            InfoRow(icon: "2.circle.fill", text: "They click the link")
                            InfoRow(icon: "3.circle.fill", text: "If they don't have the app: web page plays the fart + prompts install")
                            InfoRow(icon: "4.circle.fill", text: "If they install: fart plays in-app when they open it!")
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Send button
                        Button(action: createAndShare) {
                            if isCreatingAttack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.yellow.opacity(0.7))
                                    .cornerRadius(16)
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                    Text("Create Fart Attack")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(16)
                            }
                        }
                        .disabled(isCreatingAttack || attacksAvailable == 0 || recipientName.isEmpty)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Attack Created!", isPresented: $showingSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Fart attack created! Share the link with your victim 💨")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareURL = shareURL {
                    ShareSheet(items: [
                        "You've been fart attacked! 💨😂 Click here: \(shareURL.absoluteString)"
                    ])
                }
            }
        }
    }
    
    private func createAndShare() {
        guard let currentUser = authManager.currentUser else {
            errorMessage = "Please sign in first"
            showingError = true
            return
        }
        
        guard attacksAvailable > 0 else {
            errorMessage = "No attacks available. Buy more!"
            showingError = true
            return
        }
        
        guard !recipientName.isEmpty else {
            errorMessage = "Please enter a recipient name"
            showingError = true
            return
        }
        
        isCreatingAttack = true
        
        Task {
            // Use identifier if provided, otherwise use name as fallback
            let identifier = recipientIdentifier.isEmpty ? recipientName : recipientIdentifier
            
            let result = await fartAttackManager.createExternalAttack(
                from: currentUser,
                recipientName: recipientName,
                recipientIdentifier: identifier
            )
            
            await MainActor.run {
                isCreatingAttack = false
                
                if result.success, let url = result.shareURL {
                    shareURL = url
                    showingSuccess = true
                    
                    // Show share sheet after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingShareSheet = true
                    }
                    
                    // Reset form
                    recipientName = ""
                    recipientIdentifier = ""
                } else {
                    errorMessage = "Failed to create fart attack. Please try again."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    ExternalFartAttackView()
        .environmentObject(AuthenticationManager())
}

