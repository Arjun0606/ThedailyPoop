import SwiftUI

struct LetterTileView: View {
    let letter: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter.uppercased())
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Theme.accent : Theme.elevatedBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Theme.accent : Theme.cardBorder, lineWidth: isSelected ? 0 : 0.5)
                )
                .scaleEffect(isSelected ? 0.92 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
