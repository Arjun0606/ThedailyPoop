import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("💬")
                                .font(.system(size: 60))
                            
                            Text("Get in Touch")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Have suggestions, found a bug, or just want to say hi? We'd love to hear from you!")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Contact Methods
                        VStack(spacing: 16) {
                            // Email
                            ContactButton(
                                icon: "envelope.fill",
                                title: "Email Us",
                                subtitle: "karjunvarma2001@gmail.com",
                                action: {
                                    if let url = URL(string: "mailto:karjunvarma2001@gmail.com?subject=Plop%20Feedback") {
                                        UIApplication.shared.open(url)
                                    }
                                },
                                onLongPress: {
                                    UIPasteboard.general.string = "karjunvarma2001@gmail.com"
                                    showingCopiedAlert = true
                                }
                            )
                            
                            // Twitter/X
                            ContactButton(
                                icon: "xmark.app.fill",
                                title: "Follow on X",
                                subtitle: "@Arjun06061",
                                action: {
                                    if let url = URL(string: "https://x.com/Arjun06061") {
                                        UIApplication.shared.open(url)
                                    }
                                },
                                onLongPress: {
                                    UIPasteboard.general.string = "@Arjun06061"
                                    showingCopiedAlert = true
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                QuickActionButton(
                                    icon: "lightbulb.fill",
                                    title: "Suggest a Feature",
                                    color: .yellow
                                ) {
                                    if let url = URL(string: "mailto:karjunvarma2001@gmail.com?subject=Plop%20Feature%20Request") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                
                                QuickActionButton(
                                    icon: "ant.fill",
                                    title: "Report a Bug",
                                    color: .red
                                ) {
                                    if let url = URL(string: "mailto:karjunvarma2001@gmail.com?subject=Plop%20Bug%20Report") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                
                                QuickActionButton(
                                    icon: "heart.fill",
                                    title: "Send Feedback",
                                    color: .pink
                                ) {
                                    if let url = URL(string: "mailto:karjunvarma2001@gmail.com?subject=Plop%20Feedback") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Footer
                        Text("We read every message and appreciate your feedback! 💩")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Contact & Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Contact info copied to clipboard")
            }
        }
    }
}

struct ContactButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

#Preview {
    ContactView()
}
