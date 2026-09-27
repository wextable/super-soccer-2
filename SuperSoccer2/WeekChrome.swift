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

/// Full-fitness rating, with the current number above a small “fit” line when condition has taken some off.
struct FitnessNumber: View {
    @Environment(\.theme) private var theme
    var current: Int
    var full: Int
    var showsFull: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(current)")
                .font(theme.type.playerOverall)
                .foregroundStyle(theme.colors.text.color)
            if showsFull {
                Text("fit \(full)")
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A rating drawn left to right. `marked` is the slice just past the filled rating: growth, or the fitness that was lost.
struct RatingBar: View {
    @Environment(\.theme) private var theme
    var track: RatingTrack
    var mark: Mark

    enum Mark {
        case condition
        case growth
    }

    var body: some View {
        Capsule()
            .fill(theme.colors.hairline.color)
            .overlay {
                GeometryReader { proxy in
                    let scale = proxy.size.width / CGFloat(RatingTrack.trackPoints)
                    ZStack(alignment: .leading) {
                        if track.markedPoints > 0 {
                            Capsule()
                                .fill(markColor)
                                .frame(
                                    width: scale * CGFloat(track.filledPoints + track.markedPoints),
                                    height: proxy.size.height
                                )
                        }
                        if track.filledPoints > 0 {
                            Capsule()
                                .fill(theme.colors.action.color)
                                .frame(width: scale * CGFloat(track.filledPoints), height: proxy.size.height)
                        }
                    }
                }
            }
            .frame(height: theme.space.sm)
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }

    private var markColor: Color {
        switch mark {
        case .condition: theme.colors.fitnessRed.color
        case .growth: theme.colors.score.color
        }
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
