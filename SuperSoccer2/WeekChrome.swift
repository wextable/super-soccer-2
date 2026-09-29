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
        .overlay {
            if theme.metrics.pixelChrome {
                Rectangle()
                    .strokeBorder(theme.colors.title.color, lineWidth: 2)
            }
        }
        .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
    }
}

/// Short position ink. The column is as wide as the longest code, so the names line up.
struct PositionMark: View {
    @Environment(\.theme) private var theme
    var position: Position

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Position.allCases, id: \.self) { item in
                Text(item.label)
                    .font(theme.type.captionNumber)
                    .lineLimit(1)
                    .hidden()
            }
            Text(position.label)
                .font(theme.type.captionNumber)
                .foregroundStyle(theme.colors.color(for: position))
                .lineLimit(1)
        }
        .accessibilityHidden(true)
    }
}

/// A section name. The pixel look puts a cyan rule under it.
struct SectionLabel: View {
    @Environment(\.theme) private var theme
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xxs) {
            Text(text)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.metrics.pixelChrome ? theme.colors.title.color : theme.colors.secondaryText.color)
            if theme.metrics.pixelChrome {
                PixelRule()
                    .frame(width: 72)
            }
        }
    }
}

/// A broken cyan rule. The light look does not use it.
struct PixelRule: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Canvas { context, size in
            let color = theme.colors.title.color
            let block: CGFloat = 6
            let gap: CGFloat = 3
            var x: CGFloat = 0
            while x < size.width {
                let width = min(block, size.width - x)
                let rect = CGRect(x: x, y: 0, width: width, height: size.height)
                context.fill(Path(rect), with: .color(color))
                x += block + gap
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
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

/// A rating drawn left to right on the 1–99 scale. The track ends at the ceiling. The fill ends at the rating.
/// Growth and lost fitness sit inside the track. The same rating is the same fill, whatever the ceiling.
struct RatingBar: View {
    @Environment(\.theme) private var theme
    var track: RatingTrack
    var mark: Mark

    enum Mark {
        case condition
        case growth
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: theme.space.sm, maxHeight: theme.space.sm)
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let scale = width / CGFloat(RatingTrack.trackPoints)
                    let trackWidth = min(width, scale * CGFloat(max(track.ceiling, 0)))
                    ZStack(alignment: .leading) {
                        bar(trackWidth, height: proxy.size.height, color: theme.colors.hairline.color)
                        if track.markedPoints > 0 {
                            bar(
                                min(trackWidth, scale * CGFloat(track.filledPoints + track.markedPoints)),
                                height: proxy.size.height,
                                color: markColor
                            )
                        }
                        if track.filledPoints > 0 {
                            bar(
                                min(trackWidth, scale * CGFloat(track.filledPoints)),
                                height: proxy.size.height,
                                color: theme.colors.action.color
                            )
                        }
                    }
                    .frame(width: width, height: proxy.size.height, alignment: .leading)
                }
            }
            .accessibilityHidden(true)
    }

    private var markColor: Color {
        switch mark {
        case .condition: theme.colors.fitnessRed.color
        case .growth: theme.colors.score.color
        }
    }

    private func bar(_ width: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: theme.metrics.pixelChrome ? 0 : height / 2, style: .continuous)
            .fill(color)
            .frame(width: max(width, 0), height: height)
    }
}

struct WeekHairline: View {
    @Environment(\.theme) private var theme

    var body: some View {
        if theme.metrics.pixelChrome {
            PixelRule()
        } else {
            Rectangle()
                .fill(theme.colors.hairline.color)
                .frame(height: theme.metrics.hairline)
        }
    }
}
