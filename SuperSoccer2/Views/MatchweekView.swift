import ComposableArchitecture
import SwiftUI

struct MatchweekView: View {
    @Bindable var store: StoreOf<MatchweekFeature>
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            Group {
                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: theme.space.lg) {
                        table
                        VStack(alignment: .leading, spacing: theme.space.lg) {
                            weekBody
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: theme.space.lg) {
                        weekBody
                        table
                    }
                }
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Week \(store.weekNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.colors.action.color)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.weekIndex)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.currentWeekIsInTheTable)
        .fullScreenCover(
            item: $store.scope(state: \.highlight, action: \.highlight)
        ) { highlightStore in
            HighlightView(store: highlightStore)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.committedWeeks)
    }

    private var weekBody: some View {
        VStack(alignment: .leading, spacing: theme.space.lg) {
            header
            if store.didFail {
                ContentUnavailableView(
                    "The week did not kick off",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Leave and open the app again.")
                )
                .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
            } else if store.fixture == nil {
                ContentUnavailableView(
                    "No fixture this week",
                    systemImage: "calendar",
                    description: Text("This club is not on the week’s list.")
                )
                .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
            } else if store.currentWeekIsInTheTable {
                results
                controls
            } else if let opponent = store.opponent {
                opponentCard(opponent)
                controls
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text("Week \(store.weekNumber)")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.userClub?.name ?? "Your club")
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            if let opponent = store.opponent {
                Text(store.userIsHome ? "Home to \(opponent.name)" : "Away at \(opponent.name)")
                    .font(theme.type.homeLine)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func opponentCard(_ opponent: Club) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(opponent.kit.primary.color)
                .frame(width: theme.metrics.accentBar)
            VStack(alignment: .leading, spacing: theme.space.xxs) {
                Text(store.userIsHome ? "Away" : "Home")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text(opponent.name)
                    .font(theme.type.opponentName)
                    .foregroundStyle(theme.colors.text.color)
                Text("Overall \(opponent.overall)")
                    .font(theme.type.overall)
                    .foregroundStyle(theme.colors.text.color)
                Text(opponent.summaryLine)
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            .padding(theme.space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.card.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
        .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(opponent.name), overall \(opponent.overall), \(opponent.summaryLine)")
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Scorelines")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            VStack(spacing: 0) {
                ForEach(Array(store.scorelines.enumerated()), id: \.element.id) { index, line in
                    scoreline(line)
                    if index < store.scorelines.count - 1 {
                        Rectangle()
                            .fill(theme.colors.hairline.color)
                            .frame(height: theme.metrics.hairline)
                    }
                }
            }
            .padding(.horizontal, theme.space.md)
            .background(theme.colors.card.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        }
    }

    private func scoreline(_ line: Matchweek.Scoreline) -> some View {
        let home = club(line.homeID)
        let away = club(line.awayID)
        let isYours = line.involves(store.userClubID)
        return HStack(spacing: theme.space.sm) {
            Text(home?.shortName ?? line.homeID)
                .font(theme.type.playerName)
                .foregroundStyle(isYours ? theme.colors.action.color : theme.colors.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(line.homeScore)")
                .font(theme.type.score)
                .foregroundStyle(theme.colors.score.color)
            Text("–")
                .font(theme.type.scoreSide)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("\(line.awayScore)")
                .font(theme.type.score)
                .foregroundStyle(theme.colors.score.color)
            Text(away?.shortName ?? line.awayID)
                .font(theme.type.playerName)
                .foregroundStyle(isYours ? theme.colors.action.color : theme.colors.text.color)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(minHeight: theme.metrics.minimumControl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(home?.name ?? line.homeID) \(line.homeScore), \(away?.name ?? line.awayID) \(line.awayScore)")
    }

    private var table: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Table")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            VStack(spacing: 0) {
                tableRow(club: "Club", played: "P", points: "Pts", difference: "GD", emphasized: false, isHeader: true)
                ForEach(store.table) { row in
                    Rectangle()
                        .fill(theme.colors.hairline.color)
                        .frame(height: theme.metrics.hairline)
                    let club = club(row.clubID)
                    tableRow(
                        club: club?.shortName ?? row.clubID,
                        played: "\(row.played)",
                        points: "\(row.points)",
                        difference: signed(row.goalDifference),
                        emphasized: row.clubID == store.userClubID,
                        isHeader: false
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(tableLabel(row: row, club: club))
                }
            }
            .padding(.horizontal, theme.space.md)
            .background(theme.colors.card.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        }
    }

    private func tableRow(
        club: String,
        played: String,
        points: String,
        difference: String,
        emphasized: Bool,
        isHeader: Bool
    ) -> some View {
        HStack(spacing: theme.space.sm) {
            Text(club)
                .font(isHeader ? theme.type.eyebrow : theme.type.playerName)
                .foregroundStyle(rowColor(emphasized: emphasized, isHeader: isHeader))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(played)
                .frame(width: theme.metrics.minimumControl, alignment: .trailing)
            Text(points)
                .frame(width: theme.metrics.minimumControl, alignment: .trailing)
            Text(difference)
                .frame(width: theme.metrics.minimumControl, alignment: .trailing)
        }
        .font(isHeader ? theme.type.eyebrow : theme.type.captionNumber)
        .foregroundStyle(isHeader ? theme.colors.secondaryText.color : theme.colors.text.color)
        .frame(minHeight: theme.metrics.minimumControl)
    }

    private func rowColor(emphasized: Bool, isHeader: Bool) -> Color {
        if isHeader { return theme.colors.secondaryText.color }
        return emphasized ? theme.colors.action.color : theme.colors.text.color
    }

    private func tableLabel(row: Standing, club: Club?) -> String {
        let name = club?.name ?? row.clubID
        return "\(name), played \(row.played), \(row.points) points, goal difference \(signed(row.goalDifference))"
    }

    private var controls: some View {
        VStack(spacing: theme.space.sm) {
            if !store.currentWeekIsInTheTable {
                Button("Kick off") {
                    store.send(.view(.kickOffButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.hasNextFixture {
                Button("Next fixture") {
                    store.send(.view(.nextFixtureButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.currentWeekIsInTheTable, store.pending != nil {
                Button("Watch the beat") {
                    store.send(.view(.replayButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.seasonIsOver {
                Text("That's the season.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func club(_ id: String) -> Club? {
        store.clubs.first { $0.id == id }
    }

    private func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }
}
