import ComposableArchitecture
import SwiftUI

struct LeadersView: View {
    @Bindable var store: StoreOf<LeadersFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                VStack(alignment: .leading, spacing: theme.space.xs) {
                    Text("The league")
                        .font(theme.type.eyebrow)
                        .foregroundStyle(theme.colors.action.color)
                    Text("Leaders")
                        .font(theme.type.display)
                        .foregroundStyle(theme.colors.text.color)
                }
                if store.isEmpty {
                    ContentUnavailableView(
                        "No matches yet",
                        systemImage: "list.number",
                        description: Text("Play a week and the leaders show up here.")
                    )
                    .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
                } else {
                    board("Goals", rows: store.goals)
                    board("Assists", rows: store.assists)
                    board("Saves", rows: store.saves)
                }
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Leaders")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $store.scope(state: \.player, action: \.player)
        ) { playerStore in
            PlayerDetailView(store: playerStore)
        }
    }

    private func board(_ title: String, rows: [LeagueLeaders.Row]) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            if rows.isEmpty {
                Text("None yet")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: theme.metrics.minimumControl)
            } else {
                WeekCard {
                    ForEach(rows) { row in
                        leaderRow(row, title: title, rank: (rows.firstIndex { $0.id == row.id } ?? 0) + 1)
                        if row.id != rows.last?.id {
                            WeekHairline()
                        }
                    }
                }
            }
        }
    }

    private func leaderRow(_ row: LeagueLeaders.Row, title: String, rank: Int) -> some View {
        Button {
            store.send(.view(.playerTapped(row.player.id)))
        } label: {
            HStack(spacing: theme.space.sm) {
                Text("\(rank)")
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(width: theme.metrics.minimumControl, alignment: .leading)
                VStack(alignment: .leading, spacing: theme.space.xxs) {
                    Text(row.player.fullName)
                        .font(theme.type.playerName)
                        .foregroundStyle(isYours(row) ? theme.colors.action.color : theme.colors.text.color)
                    Text(isYours(row) ? "Your club · \(row.clubName)" : row.clubName)
                        .font(theme.type.captionNumber)
                        .foregroundStyle(isYours(row) ? theme.colors.action.color : theme.colors.secondaryText.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(row.count)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
            }
            .frame(minHeight: theme.metrics.minimumControl)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(leaderLabel(row, title: title, rank: rank))
    }

    private func isYours(_ row: LeagueLeaders.Row) -> Bool {
        row.clubID == store.userClubID
    }

    private func leaderLabel(_ row: LeagueLeaders.Row, title: String, rank: Int) -> String {
        let club = isYours(row) ? "your club, \(row.clubName)" : row.clubName
        return "\(rank), \(row.player.fullName), \(club), \(row.count) \(title.lowercased())"
    }
}
