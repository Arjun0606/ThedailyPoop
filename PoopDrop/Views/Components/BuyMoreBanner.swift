import SwiftUI

struct BuyMoreBanner: View {
    @EnvironmentObject var fartAttackManager: FartAttackManager
    @Binding var selectedTab: Int
    
    var attacksAvailable: Int {
        fartAttackManager.inventory?.availableAttacks ?? 0
    }
    
    var body: some View {
        if attacksAvailable <= 1 {
            Button {
                withAnimation {
                    selectedTab = 5 // Attacks tab
                }
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Running low on attacks!")
                            .font(.subheadline.bold())
                        Text("Tap to get more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
