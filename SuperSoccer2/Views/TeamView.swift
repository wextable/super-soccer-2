import ComposableArchitecture
import SwiftUI

struct TeamView: View {
    @Bindable var store: StoreOf<TeamFeature>

    var body: some View {
        TeamScreen(
            club: store.club,
            played: store.played,
            points: store.points,
            goalDifference: store.goalDifference
        ) { id in
            store.send(.view(.playerTapped(id)))
        }
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
    var club: Club
    var played: Int
    var points: Int
    var goalDifference: Int
    var onPlayer: (Player.ID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                record
                roster
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
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

    private var roster: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Roster")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(club.starters) { player in
                    Button {
                        onPlayer(player.id)
                    } label: {
                        HStack(spacing: theme.space.sm) {
                            Text(player.position.label)
                                .font(theme.type.captionNumber)
                                .foregroundStyle(theme.colors.secondaryText.color)
                                .frame(width: theme.metrics.minimumControl, alignment: .leading)
                            Text(player.fullName)
                                .font(theme.type.playerName)
                                .foregroundStyle(theme.colors.text.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(player.overall)")
                                .font(theme.type.playerOverall)
                                .foregroundStyle(theme.colors.text.color)
                        }
                        .frame(minHeight: theme.metrics.minimumControl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(player.fullName), \(player.position.label), overall \(player.overall)")
                    if player.id != club.starters.last?.id {
                        WeekHairline()
                    }
                }
            }
        }
    }
}
