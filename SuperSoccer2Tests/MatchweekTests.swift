import ComposableArchitecture
import Foundation
import os
import Testing
@testable import SuperSoccer2

@Suite
struct LeagueTableTests {
    @Test func pointsAndGoalDifferenceComeFromTheScorelines() {
        let lines = [
            Matchweek.Scoreline(homeID: "home", awayID: "away", homeScore: 2, awayScore: 0),
            Matchweek.Scoreline(homeID: "draw-home", awayID: "draw-away", homeScore: 1, awayScore: 1)
        ]
        let next = LeagueTable.applying(lines, to: LeagueTable.zeros(clubIDs: ["home", "away", "draw-home", "draw-away"]))
        let rows = Dictionary(uniqueKeysWithValues: next.map { ($0.clubID, $0) })
        #expect(rows["home"]?.played == 1)
        #expect(rows["home"]?.points == 3)
        #expect(rows["home"]?.goalDifference == 2)
        #expect(rows["away"]?.points == 0)
        #expect(rows["away"]?.goalDifference == -2)
        #expect(rows["draw-home"]?.points == 1)
        #expect(rows["draw-away"]?.points == 1)
        #expect(rows["draw-home"]?.goalDifference == 0)
        #expect(rows["draw-away"]?.goalDifference == 0)
    }

    @Test func rankUsesPointsThenGoalDifferenceThenOverall() throws {
        let season = LeagueDraft.makeLeague(seed: 1)
        let city = try #require(season.clubs.first { $0.id == "manchester-city" })
        let norwich = try #require(season.clubs.first { $0.id == "norwich-city" })
        #expect(city.overall > norwich.overall)
        let ids = season.clubs.map(\.id)

        let byPoints = LeagueTable.ranked(marking(ids, norwich.id, points: 3, goalsFor: 1), clubs: season.clubs)
        #expect(byPoints.first?.clubID == norwich.id)

        let byDifference = LeagueTable.ranked(
            marking(ids, norwich.id, points: 3, goalsFor: 2, and: city.id, points: 3, goalsFor: 1),
            clubs: season.clubs
        )
        let norwichPlace = try #require(byDifference.firstIndex { $0.clubID == norwich.id })
        let cityPlace = try #require(byDifference.firstIndex { $0.clubID == city.id })
        #expect(norwichPlace < cityPlace)

        let byOverall = LeagueTable.ranked(
            marking(ids, norwich.id, points: 3, goalsFor: 1, and: city.id, points: 3, goalsFor: 1),
            clubs: season.clubs
        )
        let tiedNorwich = try #require(byOverall.firstIndex { $0.clubID == norwich.id })
        let tiedCity = try #require(byOverall.firstIndex { $0.clubID == city.id })
        #expect(tiedCity < tiedNorwich)
    }
}

@Suite
struct MatchweekPlayTests {
    @Test func aWeekResolvesEveryFixtureWithTheMatchFunction() throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let weeks = LeagueDraft.weeks(in: season.fixtures)
        #expect(weeks.count == 38)
        #expect(weeks.allSatisfy { $0.count == 10 })
        let firstWeekTeams = Set(weeks[0].flatMap { [$0.homeID, $0.awayID] })
        #expect(firstWeekTeams.count == 20)

        let seed = Matchweek.weekSeed(draw: 42, weekIndex: 0)
        let played = try #require(
            Matchweek.play(fixtures: weeks[0], clubs: season.clubs, userClubID: "norwich-city", seed: seed)
        )
        let again = try #require(
            Matchweek.play(fixtures: weeks[0], clubs: season.clubs, userClubID: "norwich-city", seed: seed)
        )
        #expect(played == again)
        #expect(played.scorelines.count == 10)
        #expect(played.scorelines.filter { $0.involves("norwich-city") }.count == 1)

        let clubs = Dictionary(uniqueKeysWithValues: season.clubs.map { ($0.id, $0) })
        for (index, fixture) in weeks[0].enumerated() {
            let direct = MatchSimulator.simulate(
                home: try #require(clubs[fixture.homeID]),
                away: try #require(clubs[fixture.awayID]),
                seed: seed &+ UInt64(index)
            )
            #expect(played.scorelines[index].homeScore == direct.homeScore)
            #expect(played.scorelines[index].awayScore == direct.awayScore)
        }

        let table = LeagueTable.ranked(
            LeagueTable.applying(played.scorelines, to: LeagueTable.zeros(clubIDs: season.clubs.map(\.id))),
            clubs: season.clubs
        )
        #expect(table.allSatisfy { $0.played == 1 })
        #expect(table.map(\.goalDifference).reduce(0, +) == 0)
        let points = table.map(\.points).reduce(0, +)
        #expect((20...30).contains(points))
        for pair in zip(table, table.dropFirst()) {
            if pair.0.points == pair.1.points {
                #expect(pair.0.goalDifference >= pair.1.goalDifference)
            } else {
                #expect(pair.0.points > pair.1.points)
            }
        }
    }
}

@Suite
@MainActor
struct MatchweekFeatureTests {
    @Test func kickoffWaitsForTheReelBeforeTheTableMoves() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let draws = OSAllocatedUnfairLock(initialState: 0)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = {
                draws.withLock { $0 += 1 }
                return 99
            }
        }
        store.exhaustivity = .off

        await store.send(.view(.nextFixtureButtonTapped))
        #expect(store.state.weekIndex == 0)

        await store.send(.view(.kickOffButtonTapped))
        #expect(draws.withLock { $0 } == 1)
        #expect(store.state.highlight != nil)
        #expect(store.state.pending?.scorelines.count == 10)
        #expect(store.state.standings.allSatisfy { $0.played == 0 })

        await store.send(.view(.kickOffButtonTapped))
        #expect(draws.withLock { $0 } == 1)

        await store.send(.highlight(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.highlight == nil)
        #expect(store.state.currentWeekIsInTheTable)
        #expect(store.state.standings.allSatisfy { $0.played == 1 })
        #expect(store.state.scorelines.count == 10)

        let afterWeek = store.state.standings
        await store.send(.view(.replayButtonTapped))
        #expect(store.state.highlight != nil)
        await store.send(.highlight(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.standings == afterWeek)
        #expect(store.state.highlight == nil)

        await store.send(.view(.nextFixtureButtonTapped))
        #expect(store.state.weekIndex == 1)
        #expect(store.state.currentWeekIsInTheTable == false)
        #expect(store.state.pending == nil)
        #expect(store.state.standings == afterWeek)
    }

    @Test func skipThenFullTimeStatsUpdatesTheTableOnce() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "norwich-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        store.exhaustivity = .off

        await store.send(.view(.kickOffButtonTapped))
        let finalHome = try #require(store.state.highlight?.finalHomeScore)
        let finalAway = try #require(store.state.highlight?.finalAwayScore)
        let shots = try #require(store.state.pending?.userMatch.shots)
        #expect(store.state.standings.allSatisfy { $0.played == 0 })
        #expect(store.state.weekLines.allSatisfy { $0.homeScore == nil })

        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        #expect(store.state.highlight?.phase == .fullTime)
        #expect(store.state.highlight?.commentary == "Full time.")
        #expect(store.state.highlight?.homeScore == finalHome)
        #expect(store.state.highlight?.awayScore == finalAway)
        #expect(store.state.highlight != nil)
        #expect(store.state.stats == nil)
        #expect(store.state.standings.allSatisfy { $0.played == 0 })

        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        let rows = try #require(store.state.stats?.rows)
        #expect(store.state.highlight != nil)
        #expect(store.state.stats?.title == "Full time")
        #expect(rows.map(\.minute) == shots.sorted { $0.minute < $1.minute }.map(\.minute))
        #expect(rows.map(\.result) == shots.sorted { $0.minute < $1.minute }.map(\.result))
        #expect(store.state.standings.allSatisfy { $0.played == 0 })

        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.highlight == nil)
        #expect(store.state.stats == nil)
        #expect(store.state.currentWeekIsInTheTable)
        #expect(store.state.standings.allSatisfy { $0.played == 1 })
        #expect(store.state.scorelines.count == 10)
        #expect(store.state.weekLines.allSatisfy { $0.homeScore != nil })

        let afterWeek = store.state.standings
        await store.send(.view(.replayButtonTapped))
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.standings == afterWeek)
        #expect(store.state.highlight == nil)
        #expect(store.state.stats == nil)
    }

    @Test func theWeekIsFourTabsAndAPlayerPushes() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        }
        #expect(MatchweekFeature.State.Tab.allCases == [.club, .table, .week, .match])
        #expect(store.state.tab == .match)
        #expect(store.state.weekLines.count == 10)
        #expect(store.state.keyPlayers.count == 3)
        let best = try #require(store.state.opponent?.starters.map(\.overall).max())
        #expect(store.state.keyPlayers.first?.overall == best)
        let player = try #require(store.state.userClub?.starters.first)

        await store.send(.view(.tabSelected(.club))) {
            $0.tab = .club
        }
        await store.send(.view(.playerTapped(player.id))) {
            $0.player = PlayerDetailFeature.State(player: player)
        }
        #expect(store.state.player?.player.fullName == player.fullName)
        await store.send(.player(.dismiss)) {
            $0.player = nil
        }
        await store.send(.view(.playerTapped("missing")))
    }

    @Test func theLastWeekDoesNotStartAnotherSeason() async {
        let season = LeagueDraft.makeLeague(seed: 1)
        var state = MatchweekFeature.State(userClubID: "norwich-city", season: season)
        state.weekIndex = state.weeks.count - 1
        state.committedWeeks = state.weeks.count
        let store = TestStore(initialState: state) {
            MatchweekFeature()
        }

        #expect(store.state.seasonIsOver)
        #expect(store.state.hasNextFixture == false)
        await store.send(.view(.nextFixtureButtonTapped))
        #expect(store.state.weekIndex == state.weeks.count - 1)
    }
}

private func marking(
    _ ids: [String],
    _ firstID: String,
    points firstPoints: Int,
    goalsFor firstGoals: Int,
    and secondID: String? = nil,
    points secondPoints: Int = 0,
    goalsFor secondGoals: Int = 0
) -> [Standing] {
    LeagueTable.zeros(clubIDs: ids).map { row in
        var copy = row
        if row.clubID == firstID {
            copy.played = 1
            copy.points = firstPoints
            copy.goalsFor = firstGoals
        } else if row.clubID == secondID {
            copy.played = 1
            copy.points = secondPoints
            copy.goalsFor = secondGoals
        }
        return copy
    }
}
