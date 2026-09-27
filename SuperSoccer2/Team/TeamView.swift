import ComposableArchitecture
import SwiftUI

struct TeamView: View {
    @Bindable var store: StoreOf<TeamFeature>

    var body: some View {
        TeamScreen(
            club: store.club,
            played: store.played,
            points: store.points,
            goalDifference: store.goalDifference,
            canManage: store.canManage,
            onPlayer: { store.send(.view(.playerTapped($0))) },
            onRest: store.canManage ? { store.send(.view(.restStarter($0))) } : nil
        )
        .navigationTitle(store.club.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $store.scope(state: \.player, action: \.player)
        ) { playerStore in
            PlayerDetailView(store: playerStore)
        }
    }
}

/// Squad, ratings, and record. The Club tab and the table drill-in share this layout.
struct TeamScreen: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var club: Club
    var played: Int
    var points: Int
    var goalDifference: Int
    var canManage: Bool = false
    var onPlayer: (Player.ID) -> Void
    var onRest: ((Player.ID) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                record
                if !club.injuryLines.isEmpty {
                    injuries
                }
                roster(title: "Starting", players: club.starters, canRest: canManage)
                roster(title: "Bench", players: club.bench, canRest: false)
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: club.starters.map(\.id))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(club.name)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text("Overall \(club.overall)")
                .font(theme.type.overall)
                .foregroundStyle(theme.colors.text.color)
            Text("Attack \(club.attack)")
                .font(theme.type.homeLine)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("Defense \(club.defense)")
                .font(theme.type.homeLine)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .accessibilityElement(children: .combine)
    }

    private var record: some View {
        WeekCard {
            recordRow("Played", value: "\(played)")
            WeekHairline()
            recordRow("Points", value: "\(points)")
            WeekHairline()
            recordRow("Goal difference", value: signedGoalDifference(goalDifference))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Played \(played), \(points) points, goal difference \(signedGoalDifference(goalDifference))")
    }

    private func recordRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.type.playerName)
                .foregroundStyle(theme.colors.text.color)
            Spacer()
            Text(value)
                .font(theme.type.playerOverall)
                .foregroundStyle(theme.colors.text.color)
        }
        .frame(minHeight: theme.metrics.minimumControl)
    }

    private var injuries: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Injuries")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(Array(club.injuryLines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
                        Circle()
                            .fill(theme.colors.fitnessRed.color)
                            .frame(width: theme.space.xs, height: theme.space.xs)
                        Text(line)
                            .font(theme.type.body)
                            .foregroundStyle(theme.colors.text.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: theme.metrics.minimumControl)
                    .accessibilityElement(children: .combine)
                    if index < club.injuryLines.count - 1 {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func roster(title: String, players: [Player], canRest: Bool) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            if players.isEmpty {
                Text(title == "Bench" ? "The bench is empty." : "No one is starting.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
            } else {
                WeekCard {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        playerRow(player, canRest: canRest)
                        if index < players.count - 1 {
                            WeekHairline()
                        }
                    }
                }
            }
        }
    }

    private func playerRow(_ player: Player, canRest: Bool) -> some View {
        let band = player.fitnessBand()
        let mark = player.injury == nil ? band.label : "Out"
        let showRest = canRest && player.injury == nil && WeekBetween.bestFit(replacing: player, in: club.players) != nil
        return HStack(spacing: theme.space.sm) {
            Button {
                onPlayer(player.id)
            } label: {
                HStack(spacing: theme.space.sm) {
                    Circle()
                        .fill(bandColor(player))
                        .frame(width: theme.space.sm, height: theme.space.sm)
                        .accessibilityHidden(true)
                    Text(player.position.label)
                        .font(theme.type.captionNumber)
                        .foregroundStyle(theme.colors.secondaryText.color)
                        .frame(width: theme.metrics.minimumControl, alignment: .leading)
                    VStack(alignment: .leading, spacing: theme.space.xxs) {
                        Text(player.fullName)
                            .font(theme.type.playerName)
                            .foregroundStyle(theme.colors.text.color)
                        Text(mark)
                            .font(theme.type.captionNumber)
                            .foregroundStyle(bandColor(player))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    StarterRating(player: player)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerLabel(player, mark: mark))
            if showRest {
                Button("Rest") {
                    onRest?(player.id)
                }
                .font(theme.type.button)
                .foregroundStyle(theme.colors.action.color)
                .frame(minHeight: theme.metrics.minimumControl)
                .accessibilityLabel(restLabel(for: player))
            }
        }
        .frame(minHeight: theme.metrics.minimumControl)
    }

    private func restLabel(for player: Player) -> String {
        let incoming = WeekBetween.bestFit(replacing: player, in: club.players)?.fullName ?? "a teammate"
        return "Rest \(player.fullName) and bring in \(incoming)"
    }

    private func playerLabel(_ player: Player, mark: String) -> String {
        var label = "\(player.fullName), \(player.position.label), \(mark), overall \(player.overall)"
        if player.isStarter, player.injury == nil, player.overall != player.optimalOverall {
            label += ", full fitness \(player.optimalOverall)"
        }
        return label
    }

    private func bandColor(_ player: Player) -> Color {
        if player.injury != nil { return theme.colors.fitnessRed.color }
        return theme.colors.fitness(player.fitnessBand())
    }
}
