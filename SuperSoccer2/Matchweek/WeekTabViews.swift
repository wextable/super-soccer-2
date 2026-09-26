import ComposableArchitecture
import SwiftUI

struct ClubTab: View {
    @Bindable var store: StoreOf<MatchweekFeature>

    var body: some View {
        if let club = store.userClub {
            TeamScreen(
                club: club,
                played: store.userStanding?.played ?? 0,
                points: store.userStanding?.points ?? 0,
                goalDifference: store.userStanding?.goalDifference ?? 0,
                canManage: true,
                offers: store.skillOffers,
                choices: store.skillChoices,
                onPlayer: { store.send(.view(.playerTapped($0))) },
                onRest: { store.send(.view(.restStarter($0))) },
                onSkill: { store.send(.view(.skillStatTapped($0, $1))) }
            )
        } else {
            TeamMissing()
        }
    }
}

private struct TeamMissing: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ContentUnavailableView(
            "No club",
            systemImage: "person.3",
            description: Text("This week has no squad.")
        )
        .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
        .themeScreen()
    }
}

struct TableTab: View {
    let store: StoreOf<MatchweekFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                Text("Week \(store.weekNumber)")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Button("Leaders") {
                    store.send(.view(.leadersButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
                if store.seasonIsOver {
                    Button("Championship") {
                        store.send(.view(.championshipButtonTapped))
                    }
                    .buttonStyle(ThemeActionButtonStyle())
                }
                WeekCard {
                    tableRow(club: "Club", played: "P", points: "Pts", difference: "GD", emphasized: false, isHeader: true)
                    ForEach(store.table) { row in
                        WeekHairline()
                        let club = store.clubs.first { $0.id == row.clubID }
                        Button {
                            store.send(.view(.teamButtonTapped(row.clubID)))
                        } label: {
                            tableRow(
                                club: club?.name ?? row.clubID,
                                played: "\(row.played)",
                                points: "\(row.points)",
                                difference: signedGoalDifference(row.goalDifference),
                                emphasized: row.clubID == store.userClubID,
                                isHeader: false
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tableLabel(row: row, club: club))
                    }
                }
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
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
                .lineLimit(2)
                .multilineTextAlignment(.leading)
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
        return "\(name), played \(row.played), \(row.points) points, goal difference \(signedGoalDifference(row.goalDifference))"
    }
}

struct WeekTab: View {
    @Bindable var store: StoreOf<MatchweekFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                Text("Week \(store.weekNumber)")
                    .font(theme.type.display)
                    .foregroundStyle(theme.colors.text.color)
                if store.weekLines.isEmpty {
                    ContentUnavailableView(
                        "No fixture this week",
                        systemImage: "calendar",
                        description: Text("This club is not on the week’s list.")
                    )
                    .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
                } else {
                    fixtures
                }
                footer
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
    }

    private var fixtures: some View {
        WeekCard {
            ForEach(store.weekLines) { line in
                fixtureRow(line)
                if line.id != store.weekLines.last?.id {
                    WeekHairline()
                }
            }
        }
    }

    private func fixtureRow(_ line: MatchweekFeature.State.WeekLine) -> some View {
        let home = store.clubs.first { $0.id == line.homeID }
        let away = store.clubs.first { $0.id == line.awayID }
        let isYours = line.homeID == store.userClubID || line.awayID == store.userClubID
        return HStack(spacing: theme.space.sm) {
            Text(store.fixtureNames[line.homeID] ?? line.homeID)
                .font(theme.type.playerName)
                .foregroundStyle(isYours ? theme.colors.action.color : theme.colors.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let homeScore = line.homeScore, let awayScore = line.awayScore {
                Text("\(homeScore)")
                    .font(theme.type.score)
                    .foregroundStyle(theme.colors.score.color)
                Text("–")
                    .font(theme.type.scoreSide)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text("\(awayScore)")
                    .font(theme.type.score)
                    .foregroundStyle(theme.colors.score.color)
            } else {
                Text("v")
                    .font(theme.type.scoreSide)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            Text(store.fixtureNames[line.awayID] ?? line.awayID)
                .font(theme.type.playerName)
                .foregroundStyle(isYours ? theme.colors.action.color : theme.colors.text.color)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(minHeight: theme.metrics.minimumControl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fixtureLabel(line, home: home, away: away))
    }

    private func fixtureLabel(_ line: MatchweekFeature.State.WeekLine, home: Club?, away: Club?) -> String {
        let homeName = home?.name ?? line.homeID
        let awayName = away?.name ?? line.awayID
        let homeBit = store.places[line.homeID].map { "\($0), \(homeName)" } ?? homeName
        let awayBit = store.places[line.awayID].map { "\($0), \(awayName)" } ?? awayName
        if let homeScore = line.homeScore, let awayScore = line.awayScore {
            return "\(homeBit) \(homeScore), \(awayBit) \(awayScore)"
        }
        return "\(homeBit) versus \(awayBit)"
    }

    @ViewBuilder
    private var footer: some View {
        if store.hasNextFixture {
            Button("Advance week") {
                store.send(.view(.nextFixtureButtonTapped))
            }
            .buttonStyle(ThemeActionButtonStyle())
        }
        if store.seasonIsOver {
            Text("That's the season.")
                .font(theme.type.body)
                .foregroundStyle(theme.colors.secondaryText.color)
            Button("Championship") {
                store.send(.view(.championshipButtonTapped))
            }
            .buttonStyle(ThemeActionButtonStyle())
        }
    }
}

struct MatchTab: View {
    @Bindable var store: StoreOf<MatchweekFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
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
                } else if let opponent = store.opponent {
                    opponentCard(opponent)
                    if !store.keyPlayers.isEmpty {
                        keyPlayers
                    }
                    controls
                }
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .alert($store.scope(state: \.seasonAlert, action: \.seasonAlert))
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
            if let homeShort = store.playedHomeShort,
               let awayShort = store.playedAwayShort,
               let homeScore = store.playedHomeScore,
               let awayScore = store.playedAwayScore {
                playedScore(homeShort: homeShort, awayShort: awayShort, homeScore: homeScore, awayScore: awayScore)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func playedScore(homeShort: String, awayShort: String, homeScore: Int, awayScore: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
            Text(homeShort)
                .font(theme.type.scoreSide)
            Text("\(homeScore)")
                .font(theme.type.score)
                .foregroundStyle(theme.colors.score.color)
            Text("–")
                .font(theme.type.scoreSide)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("\(awayScore)")
                .font(theme.type.score)
                .foregroundStyle(theme.colors.score.color)
            Text(awayShort)
                .font(theme.type.scoreSide)
        }
        .foregroundStyle(theme.colors.text.color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Full time, \(homeShort) \(homeScore), \(awayShort) \(awayScore)")
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
                Text("Attack \(opponent.attack)")
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text("Defense \(opponent.defense)")
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
        .accessibilityLabel("\(opponent.name), overall \(opponent.overall), attack \(opponent.attack), defense \(opponent.defense)")
    }

    private var keyPlayers: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Key players")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(store.keyPlayers) { player in
                    Button {
                        store.send(.view(.playerTapped(player.id)))
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
                    if player.id != store.keyPlayers.last?.id {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: theme.space.sm) {
            if !store.currentWeekIsInTheTable {
                Button("Kick off") {
                    store.send(.view(.kickOffButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
                Button("Simulate match") {
                    store.send(.view(.simulateMatchButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.currentWeekIsInTheTable, store.pending != nil {
                Button("Watch the beat") {
                    store.send(.view(.replayButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.hasNextFixture {
                Button("Advance week") {
                    store.send(.view(.nextFixtureButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.seasonIsOver {
                Text("That's the season.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Championship") {
                    store.send(.view(.championshipButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            #if DEBUG
            if !store.seasonIsOver {
                Button("SIMULATE SEASON") {
                    store.send(.view(.simulateSeasonButtonTapped))
                }
                .buttonStyle(ThemeDangerButtonStyle())
            }
            #endif
        }
    }
}

func signedGoalDifference(_ value: Int) -> String {
    value > 0 ? "+\(value)" : "\(value)"
}
