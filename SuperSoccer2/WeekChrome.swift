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
/// The column is always as wide as the longest reading, so the bar beside it keeps one right edge.
struct FitnessNumber: View {
    @Environment(\.theme) private var theme
    var current: Int
    var full: Int
    var showsFull: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(Self.ratingSample)
                .font(theme.type.playerOverall)
                .lineLimit(1)
                .hidden()
            Text(Self.fitnessSample)
                .font(theme.type.captionNumber)
                .lineLimit(1)
                .hidden()
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(current)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
                    .lineLimit(1)
                if showsFull {
                    Text("fit \(full)")
                        .font(theme.type.captionNumber)
                        .foregroundStyle(theme.colors.secondaryText.color)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// A rating stops at 99. Both samples stay in the column so a “fit” line does not shorten the bar.
    static let ratingSample = "99"
    static let fitnessSample = "fit 99"
}

/// Stat name reserved at the width of the longest rating, so every bar starts on the same line.
struct RatingLabel: View {
    @Environment(\.theme) private var theme
    var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(PlayerStat.allCases, id: \.self) { stat in
                Text(stat.label)
                    .font(theme.type.playerName)
                    .lineLimit(1)
                    .hidden()
            }
            Text(text)
                .font(theme.type.playerName)
                .foregroundStyle(theme.colors.text.color)
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }
}

/// `80→85` or `99`. The column reserves the widest reading so a growth arrow does not shorten the bar.
struct GrowthReading: View {
    @Environment(\.theme) private var theme
    var reading: String

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(Self.widest)
                .font(theme.type.playerOverall)
                .lineLimit(1)
                .hidden()
            Text(reading)
                .font(theme.type.playerOverall)
                .foregroundStyle(theme.colors.text.color)
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }

    /// Two digits, the same arrow `SkillProjection` draws, then two digits. A rating stops at 99.
    static let widest = SkillProjection.make(current: 90, boost: 9).reading
}

/// A rating drawn left to right on one shared track. Growth and lost fitness sit inside that track. The fill is the rating.
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
            .frame(maxWidth: .infinity, minHeight: theme.space.sm, maxHeight: theme.space.sm)
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let scale = width / CGFloat(RatingTrack.trackPoints)
                    ZStack(alignment: .leading) {
                        if track.markedPoints > 0 {
                            Capsule()
                                .fill(markColor)
                                .frame(
                                    width: min(width, scale * CGFloat(track.filledPoints + track.markedPoints)),
                                    height: proxy.size.height
                                )
                        }
                        if track.filledPoints > 0 {
                            Capsule()
                                .fill(theme.colors.action.color)
                                .frame(
                                    width: min(width, scale * CGFloat(track.filledPoints)),
                                    height: proxy.size.height
                                )
                        }
                    }
                    .frame(width: width, height: proxy.size.height, alignment: .leading)
                }
            }
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
