import ComposableArchitecture
import SwiftUI

struct PlayerDetailView: View {
    let store: StoreOf<PlayerDetailFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                if let role = store.roleLine {
                    pager(role)
                }
                header
                if store.showsExperience {
                    experience
                }
                ratings
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle(store.player.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pager(_ role: String) -> some View {
        HStack(spacing: theme.space.sm) {
            stepButton(
                "chevron.left",
                label: "Previous player",
                enabled: store.canShowPreviousPlayer
            ) {
                store.send(.view(.previousPlayerTapped))
            }
            Text(role)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            stepButton(
                "chevron.right",
                label: "Next player",
                enabled: store.canShowNextPlayer
            ) {
                store.send(.view(.nextPlayerTapped))
            }
        }
    }

    private func stepButton(
        _ systemName: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(theme.type.button)
                .frame(minWidth: theme.metrics.minimumControl, minHeight: theme.metrics.minimumControl)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? theme.colors.action.color : theme.colors.secondaryText.color)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(positionName)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.player.fullName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            HStack(spacing: theme.space.sm) {
                ClubCrest(clubID: store.clubID)
                Text(store.clubName)
                    .font(theme.type.tagline)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            Text("Age \(store.player.age)")
                .font(theme.type.homeLine)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("Overall \(store.player.overall)")
                .font(theme.type.overall)
                .foregroundStyle(theme.colors.text.color)
            if showsFitnessDrop {
                Text("Full fitness \(store.player.optimalOverall)")
                    .font(theme.type.homeLine)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            Text(fitnessLine)
                .font(theme.type.homeLine)
                .foregroundStyle(fitnessColor)
            if let cause = store.player.injury?.cause, cause.isEmpty == false {
                Text(cause)
                    .font(theme.type.tagline)
                    .foregroundStyle(theme.colors.text.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var experience: some View {
        let progress = ExperienceProgress.make(player: store.player)
        return WeekCard {
            HStack(spacing: theme.space.sm) {
                RatingLabel(text: "Level \(progress.level)")
                RatingBar(track: progress.track, mark: .condition)
                ExperienceReading(reading: progress.reading)
            }
            .frame(minHeight: theme.metrics.minimumControl)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Level \(progress.level), \(progress.current) of \(progress.required) experience, \(progress.remaining) to the next level"
        )
    }

    private var ratings: some View {
        WeekCard {
            ForEach(Array(PlayerStat.allCases.enumerated()), id: \.element) { index, stat in
                ratingRow(stat, isLast: index == PlayerStat.allCases.count - 1)
            }
        }
    }

    private func ratingRow(_ stat: PlayerStat, isLast: Bool) -> some View {
        let full = store.player.ratings.value(for: stat)
        let current = store.player.playingRating(stat)
        let potential = store.player.potential.value(for: stat)
        let degraded = current != full
        return VStack(spacing: 0) {
            HStack(spacing: theme.space.sm) {
                RatingLabel(text: stat.label)
                RatingBar(track: .fitness(full: full, current: current, potential: potential), mark: .condition)
                FitnessNumber(current: current, full: full, showsFull: degraded)
            }
            .frame(minHeight: theme.metrics.minimumControl)
            if !isLast {
                WeekHairline()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ratingLabel(stat.label, current: current, full: full, degraded: degraded))
    }

    private func ratingLabel(_ name: String, current: Int, full: Int, degraded: Bool) -> String {
        if degraded {
            return "\(name) \(current), full fitness \(full)"
        }
        return "\(name) \(current)"
    }

    private var fitnessLine: String {
        if let injury = store.player.injury {
            let weeks = injury.weeksLeft == 1 ? "1 week" : "\(injury.weeksLeft) weeks"
            return "Out · \(injury.label) · \(weeks)"
        }
        return "\(store.player.fitnessBand().label) · fitness \(store.player.condition)"
    }

    private var showsFitnessDrop: Bool {
        store.player.isStarter
            && store.player.injury == nil
            && store.player.overall != store.player.optimalOverall
    }

    private var fitnessColor: Color {
        if store.player.injury != nil { return theme.colors.fitnessRed.color }
        return theme.colors.fitness(store.player.fitnessBand())
    }

    private var positionName: String {
        store.player.position.title
    }
}

/// `40/110`. The column stays as wide as a three-digit fraction so the bar keeps one right edge.
private struct ExperienceReading: View {
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

    static let widest = "999/999"
}
