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
            Button("Rest, bring in \(bestFit.fullName)") {
                store.send(.view(.bestFitTapped))
            }
            .buttonStyle(ThemeActionButtonStyle())
            .accessibilityLabel("Rest \(store.player.fullName) and bring in \(bestFit.fullName)")
            if !store.alternatives.isEmpty {
                Text("Or someone else")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                WeekCard {
                    ForEach(Array(store.alternatives.enumerated()), id: \.element.id) { index, player in
                        Button {
                            store.send(.view(.alternativeTapped(player.id)))
                        } label: {
                            HStack {
                                Text(player.fullName)
                                    .font(theme.type.playerName)
                                    .foregroundStyle(theme.colors.text.color)
                                Spacer()
                                Text("\(player.overall)")
                                    .font(theme.type.playerOverall)
                                    .foregroundStyle(theme.colors.text.color)
                            }
                            .frame(minHeight: theme.metrics.minimumControl)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Bring in \(player.fullName), overall \(player.overall)")
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

    private var fitnessColor: Color {
        if store.player.injury != nil { return theme.colors.fitnessRed.color }
        switch store.player.fitnessBand() {
        case .green: return theme.colors.fitnessGreen.color
        case .yellow: return theme.colors.fitnessYellow.color
        case .red: return theme.colors.fitnessRed.color
        }
    }

    private var positionName: String {
        switch store.player.position {
        case .keeper: "Keeper"
        case .defender: "Defender"
        case .midfielder: "Midfielder"
        case .forward: "Forward"
        }
    }
}
