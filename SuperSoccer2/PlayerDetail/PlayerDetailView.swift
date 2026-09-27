import ComposableArchitecture
import SwiftUI

struct PlayerDetailView: View {
    let store: StoreOf<PlayerDetailFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                if store.canManage, let bestFit = store.bestFit {
                    swap(bestFit)
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

    private func swap(_ bestFit: Player) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Bring in")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            Button {
                store.send(.view(.bestFitTapped))
            } label: {
                VStack(spacing: theme.space.xxs) {
                    Text("Rest, bring in \(bestFit.fullName)")
                    Text("\(bestFit.overall) · \(bestFit.fitnessBand().label) \(bestFit.condition)")
                        .font(theme.type.captionNumber)
                }
            }
            .buttonStyle(ThemeActionButtonStyle())
            .accessibilityLabel(
                "Rest \(store.player.fullName) and bring in \(bestFit.fullName), overall \(bestFit.overall), \(bestFit.fitnessBand().label), fitness \(bestFit.condition)"
            )
            if !store.alternatives.isEmpty {
                Text("Or someone else")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                WeekCard {
                    ForEach(Array(store.alternatives.enumerated()), id: \.element.id) { index, player in
                        Button {
                            store.send(.view(.alternativeTapped(player.id)))
                        } label: {
                            HStack(spacing: theme.space.sm) {
                                Circle()
                                    .fill(theme.colors.fitness(player.fitnessBand()))
                                    .frame(width: theme.space.sm, height: theme.space.sm)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: theme.space.xxs) {
                                    Text(player.fullName)
                                        .font(theme.type.playerName)
                                        .foregroundStyle(theme.colors.text.color)
                                    Text("\(player.fitnessBand().label) · \(player.condition)")
                                        .font(theme.type.captionNumber)
                                        .foregroundStyle(theme.colors.fitness(player.fitnessBand()))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(player.overall)")
                                    .font(theme.type.playerOverall)
                                    .foregroundStyle(theme.colors.text.color)
                            }
                            .frame(minHeight: theme.metrics.minimumControl)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "Bring in \(player.fullName), overall \(player.overall), \(player.fitnessBand().label), fitness \(player.condition)"
                        )
                        if index < store.alternatives.count - 1 {
                            WeekHairline()
                        }
                    }
                }
            }
        }
    }

    private var ratings: some View {
        WeekCard {
            ratingRow("Speed", store.player.ratings.speed, isLast: false)
            ratingRow("Shooting", store.player.ratings.shooting, isLast: false)
            ratingRow("Passing", store.player.ratings.passing, isLast: false)
            ratingRow("Dribbling", store.player.ratings.dribbling, isLast: false)
            ratingRow("Defending", store.player.ratings.defending, isLast: false)
            ratingRow("Goalkeeping", store.player.ratings.goalkeeping, isLast: true)
        }
    }

    private func ratingRow(_ name: String, _ value: Int, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(theme.type.playerName)
                    .foregroundStyle(theme.colors.text.color)
                Spacer()
                Text("\(value)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
            }
            .frame(minHeight: theme.metrics.minimumControl)
            if !isLast {
                WeekHairline()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) \(value)")
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
