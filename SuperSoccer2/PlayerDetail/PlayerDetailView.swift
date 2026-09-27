import ComposableArchitecture
import SwiftUI

struct PlayerDetailView: View {
    let store: StoreOf<PlayerDetailFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                ratings
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle(store.player.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(positionName)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.player.fullName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text(store.clubName)
                .font(theme.type.tagline)
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
        }
        .accessibilityElement(children: .combine)
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
        let degraded = current != full
        return VStack(spacing: 0) {
            HStack(spacing: theme.space.sm) {
                Text(stat.label)
                    .font(theme.type.playerName)
                    .foregroundStyle(theme.colors.text.color)
                RatingBar(track: .fitness(full: full, current: current), mark: .condition)
                    .frame(maxWidth: .infinity)
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
