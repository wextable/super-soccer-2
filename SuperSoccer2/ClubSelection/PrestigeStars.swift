import SwiftUI

/// Five stars. Half stars are allowed. The lowest rating this screen shows is one full star.
struct PrestigeStars: View {
    var rating: Double
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.space.xxs) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(at: index))
                    .foregroundStyle(isLit(index) ? theme.colors.score.color : theme.colors.secondaryText.color.opacity(0.45))
            }
        }
        .font(.system(.title3))
        .accessibilityHidden(true)
    }

    private func symbol(at index: Int) -> String {
        let star = Double(index) + 1
        if rating >= star { return "star.fill" }
        if rating >= star - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }

    private func isLit(_ index: Int) -> Bool {
        rating >= Double(index) + 0.5
    }
}
