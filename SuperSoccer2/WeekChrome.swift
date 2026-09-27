import SwiftUI

struct WeekCard<Content: View>: View {
    @Environment(\.theme) private var theme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, theme.space.md)
        .background(theme.colors.card.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
        .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
    }
}

/// The rating a starter would play at. When fitness has taken some off, the full-fitness number sits under it.
struct StarterRating: View {
    @Environment(\.theme) private var theme
    var player: Player

    private var showsDrop: Bool {
        player.isStarter && player.injury == nil && player.overall != player.optimalOverall
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(player.overall)")
                .font(theme.type.playerOverall)
                .foregroundStyle(theme.colors.text.color)
            if showsDrop {
                Text("fit \(player.optimalOverall)")
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
        }
        .accessibilityHidden(true)
    }
}

struct WeekHairline: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.colors.hairline.color)
            .frame(height: theme.metrics.hairline)
    }
}
