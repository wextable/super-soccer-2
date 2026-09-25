import ComposableArchitecture
import SwiftUI

struct MatchStatsView: View {
    @Bindable var store: StoreOf<MatchStatsFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                if store.rows.isEmpty {
                    ContentUnavailableView(
                        "No shots",
                        systemImage: "soccerball",
                        description: Text("The match produced none.")
                    )
                    .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
                } else {
                    shots
                }
                Button("Back to the week") {
                    store.send(.view(.backButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(store.title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
                Text(store.homeShort)
                    .font(theme.type.scoreSide)
                Text("\(store.homeGoals)")
                    .font(theme.type.scoreHero)
                    .foregroundStyle(theme.colors.score.color)
                Text("–")
                    .font(theme.type.scoreSide)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text("\(store.awayGoals)")
                    .font(theme.type.scoreHero)
                    .foregroundStyle(theme.colors.score.color)
                Text(store.awayShort)
                    .font(theme.type.scoreSide)
            }
            .foregroundStyle(theme.colors.text.color)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(store.title), \(store.homeShort) \(store.homeGoals), \(store.awayShort) \(store.awayGoals)")
        }
    }

    private var shots: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Shots")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(store.rows) { row in
                    shotRow(row)
                    if row.id != store.rows.last?.id {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func shotRow(_ row: MatchStatsFeature.State.Row) -> some View {
        HStack(spacing: theme.space.sm) {
            Text("\(row.minute)'")
                .font(theme.type.minute)
                .foregroundStyle(theme.colors.secondaryText.color)
                .frame(width: theme.metrics.minimumControl, alignment: .leading)
            Text(row.shooter)
                .font(theme.type.playerName)
                .foregroundStyle(theme.colors.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(resultLabel(row))
                .font(theme.type.overall)
                .foregroundStyle(row.result == .goal ? theme.colors.score.color : theme.colors.secondaryText.color)
        }
        .frame(minHeight: theme.metrics.minimumControl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.minute) minutes, \(row.shooter), \(resultLabel(row))")
    }

    private func resultLabel(_ row: MatchStatsFeature.State.Row) -> String {
        switch row.result {
        case .goal:
            row.isPenalty ? "Penalty goal" : "Goal"
        case .save:
            "Save"
        case .miss:
            "Miss"
        }
    }
}
