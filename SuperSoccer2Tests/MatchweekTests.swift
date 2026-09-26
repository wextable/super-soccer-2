import ComposableArchitecture
import Foundation
import os
import Testing
@testable import SuperSoccer2

@Suite
struct LeagueLeadersTests {
    @Test func aGoalCreditsTheShooterAndPasserAndASaveCreditsTheKeeper() throws {
        let season = LeagueDraft.makeLeague(seed: 1)
        let home = try #require(season.clubs.first { $0.id == "manchester-city" })
        let away = try #require(season.clubs.first { $0.id == "norwich-city" })
        let shooter = try #require(home.starters.first { $0.position == .forward })
        let passer = try #require(home.starters.first { $0.id != shooter.id && $0.position == .midfielder })
        let awayShooter = try #require(away.starters.first { $0.position == .forward })
        let goal = Shot(
            id: 0,
            type: .regular,
            result: .goal,
            shooter: shooter,
            passer: passer,
            keeper: away.keeper,
            minute: 4,
            isHome: true
        )
        let penalty = Shot(
            id: 1,
            type: .penalty,
            result: .goal,
            shooter: shooter,
            passer: nil,
            keeper: away.keeper,
            minute: 12,
            isHome: true
        )
        let save = Shot(
            id: 2,
            type: .regular,
            result: .save,
            shooter: awayShooter,
            passer: nil,
            keeper: home.keeper,
            minute: 20,
            isHome: false
        )
        let miss = Shot(
            id: 3,
            type: .regular,
            result: .miss,
            shooter: awayShooter,
            passer: passer,
            keeper: home.keeper,
            minute: 30,
            isHome: false
        )
        let result = MatchResult(
            homeScore: 2,
            awayScore: 0,
            shots: [goal, penalty, save, miss],
            highlight: goal,
            commentary: "",
            seed: 1
        )
        let tallies = Dictionary(
            uniqueKeysWithValues: LeagueLeaders.tally(home: home, away: away, result: result).map { ($0.playerID, $0) }
        )
        #expect(tallies[shooter.id]?.goals == 2)
        #expect(tallies[shooter.id]?.assists == 0)
        #expect(tallies[shooter.id]?.clubID == home.id)
        #expect(tallies[passer.id]?.assists == 1)
        #expect(tallies[passer.id]?.goals == 0)
        #expect(tallies[home.keeper.id]?.saves == 1)
        #expect(tallies[home.keeper.id]?.clubID == home.id)
        #expect(tallies[awayShooter.id] == nil)
        #expect(tallies[away.keeper.id] == nil)
    }
}

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
        let scored = played.scorelines.reduce(0) { $0 + $1.homeScore + $1.awayScore }
        #expect(played.tallies.map(\.goals).reduce(0, +) == scored)
        #expect(played.tallies.map(\.assists).reduce(0, +) <= scored)
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

        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.highlight == nil)
        #expect(store.state.currentWeekIsInTheTable)
        #expect(store.state.standings.allSatisfy { $0.played == 1 })
        #expect(store.state.scorelines.count == 10)

        let afterWeek = store.state.standings
        await store.send(.view(.replayButtonTapped))
        #expect(store.state.highlight != nil)
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
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
        #expect(rows.map(\.minute) == listedShots(shots).map(\.minute))
        #expect(rows.map(\.result) == listedShots(shots).map(\.result))
        #expect(rows.map(\.name) == listedShots(shots).map { shot in
            shot.result == .save ? shot.keeper.fullName : shot.shooter.fullName
        })
        #expect(rows.allSatisfy { $0.result != .miss })
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
        #expect(store.state.tab == .club)
        #expect(store.state.weekLines.count == 10)
        #expect(store.state.keyPlayers.count == 3)
        let best = try #require(store.state.opponent?.starters.map(\.overall).max())
        #expect(store.state.keyPlayers.first?.overall == best)
        let player = try #require(store.state.userClub?.starters.first)

        await store.send(.view(.tabSelected(.table))) {
            $0.tab = .table
        }
        await store.send(.view(.tabSelected(.club))) {
            $0.tab = .club
        }
        await store.send(.view(.playerTapped(player.id))) {
            $0.player = PlayerDetailFeature.State(player: player, clubName: "Manchester City")
        }
        #expect(store.state.player?.player.fullName == player.fullName)
        #expect(store.state.player?.clubName == "Manchester City")
        await store.send(.player(.dismiss)) {
            $0.player = nil
        }
        let key = try #require(store.state.keyPlayers.first)
        let opponentName = try #require(store.state.opponent?.name)
        await store.send(.view(.playerTapped(key.id))) {
            $0.player = PlayerDetailFeature.State(player: key, clubName: opponentName)
        }
        #expect(store.state.player?.player.id == key.id)
        await store.send(.player(.dismiss)) {
            $0.player = nil
        }
        await store.send(.view(.playerTapped("missing")))
    }

    @Test func leadersStayEmptyUntilTheWeekIsOnTheTable() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        }
        #expect(MatchweekFeature.State.Tab.allCases.count == 4)
        #expect(store.state.goalLeaders.isEmpty)
        #expect(store.state.assistLeaders.isEmpty)
        #expect(store.state.saveLeaders.isEmpty)
        await store.send(.view(.leadersButtonTapped)) {
            $0.leaders = LeadersFeature.State(goals: [], assists: [], saves: [], userClubID: "manchester-city")
        }
        #expect(store.state.leaders?.isEmpty == true)
        await store.send(.leaders(.dismiss)) {
            $0.leaders = nil
        }
    }

    @Test func aPlayedWeekRanksGoalsAssistsAndSaves() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        store.exhaustivity = .off

        await store.send(.view(.kickOffButtonTapped))
        #expect(store.state.goalLeaders.isEmpty)
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()

        let goals = store.state.goalLeaders
        let assists = store.state.assistLeaders
        let saves = store.state.saveLeaders
        let scored = store.state.scorelines.reduce(0) { $0 + $1.homeScore + $1.awayScore }
        let clubIDs = Set(store.state.clubs.map(\.id))
        #expect(goals.map(\.count).reduce(0, +) == scored)
        #expect(assists.map(\.count).reduce(0, +) <= scored)
        #expect(goals.allSatisfy { $0.count > 0 && clubIDs.contains($0.clubID) })
        #expect(assists.allSatisfy { $0.count > 0 && clubIDs.contains($0.clubID) })
        #expect(saves.allSatisfy { $0.count > 0 && clubIDs.contains($0.clubID) })
        for board in [goals, assists, saves] {
            for pair in zip(board, board.dropFirst()) {
                if pair.0.count == pair.1.count {
                    #expect(pair.0.player.fullName <= pair.1.player.fullName)
                } else {
                    #expect(pair.0.count > pair.1.count)
                }
            }
        }

        let leader = try #require(goals.first)
        await store.send(.view(.leadersButtonTapped))
        await store.send(.leaders(.presented(.view(.playerTapped(leader.player.id)))))
        #expect(store.state.leaders?.player == PlayerDetailFeature.State(player: leader.player, clubName: leader.clubName))

        let frozen = (goals, assists, saves)
        await store.send(.view(.replayButtonTapped))
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.goalLeaders == frozen.0)
        #expect(store.state.assistLeaders == frozen.1)
        #expect(store.state.saveLeaders == frozen.2)
    }

    @Test func theTableUsesTheFullNameAndTheWeekUsesRankAndAShortName() throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let state = MatchweekFeature.State(userClubID: "manchester-city", season: season)
        let city = try #require(state.userClub)
        let norwich = try #require(state.clubs.first { $0.id == "norwich-city" })
        #expect(city.name == "Manchester City")
        #expect(city.listName == "Man City")
        #expect(city.shortName == "MCT")
        #expect(norwich.name == "Norwich City")
        #expect(norwich.listName == "Norwich")
        #expect(norwich.shortName == "NWC")
        #expect(state.clubs.allSatisfy { $0.listName != $0.shortName })
        #expect(state.weekNumber == 1)
        let cityPlace = try #require(state.places[city.id])
        let norwichPlace = try #require(state.places[norwich.id])
        #expect(state.fixtureNames[city.id] == "\(cityPlace) Man City")
        #expect(state.fixtureNames[norwich.id] == "\(norwichPlace) Norwich")
        #expect(cityPlace == 1)
    }

    @Test func theFinishedFixtureListStoresAChampionAndOpensTheChampionship() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        var state = MatchweekFeature.State(userClubID: "manchester-city", season: season)
        #expect(state.weeks.count == 38)
        state.weekIndex = state.weeks.count - 1
        let store = TestStore(initialState: state) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        store.exhaustivity = .off

        #expect(store.state.hasNextFixture == false)
        #expect(store.state.seasonIsOver == false)
        #expect(store.state.record == nil)
        #expect(MatchweekFeature.State.Tab.allCases.count == 4)
        await store.send(.view(.championshipButtonTapped))
        #expect(store.state.championship == nil)

        await store.send(.view(.kickOffButtonTapped))
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()

        #expect(store.state.seasonIsOver)
        #expect(store.state.hasNextFixture == false)
        let record = try #require(store.state.record)
        #expect(record.championClubID == store.state.table.first?.clubID)
        #expect(record.awards.map(\.kind) == AwardKind.allCases)
        let boot = try #require(record.awards.first { $0.kind == .goldenBoot })
        #expect(boot.stats.goals == (store.state.totals.values.map(\.goals).max() ?? 0))

        await store.send(.view(.nextFixtureButtonTapped))
        #expect(store.state.weekIndex == state.weeks.count - 1)
        #expect(store.state.record == record)

        await store.send(.view(.championshipButtonTapped))
        let championID = record.championClubID
        #expect(store.state.championship?.record == record)
        #expect(store.state.championship?.goals.map(\.player.id) == store.state.goalLeaders.filter { $0.clubID == championID }.map(\.player.id))
        await store.send(.championship(.presented(.view(.awardTapped(.goldenBoot)))))
        #expect(store.state.championship?.player == PlayerDetailFeature.State(player: boot.player, clubName: boot.clubName))
        #expect(store.state.championship?.userClubID == "manchester-city")

        await store.send(.view(.replayButtonTapped))
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.statsButtonTapped))))
        await store.skipReceivedActions()
        await store.send(.stats(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.record == record)
        #expect(store.state.standings.allSatisfy { $0.played == 1 })
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

    @Test func backToWeekFromFullTimeCommitsTheTable() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "norwich-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        store.exhaustivity = .off

        await store.send(.view(.kickOffButtonTapped))
        let home = try #require(store.state.highlight?.finalHomeScore)
        let away = try #require(store.state.highlight?.finalAwayScore)
        await store.send(.highlight(.presented(.view(.skipButtonTapped))))
        await store.send(.highlight(.presented(.view(.backButtonTapped))))
        await store.skipReceivedActions()
        #expect(store.state.highlight == nil)
        #expect(store.state.stats == nil)
        #expect(store.state.currentWeekIsInTheTable)
        #expect(store.state.playedHomeScore == home)
        #expect(store.state.playedAwayScore == away)
        #expect(store.state.tab == .club)
        #expect(store.state.standings.allSatisfy { $0.played == 1 })
    }

    @Test func simulateMatchStaysOnTheMatchTabAndMatchesKickoff() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let simulated = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        simulated.exhaustivity = .off
        #expect(simulated.state.playedHomeScore == nil)

        await simulated.send(.view(.simulateMatchButtonTapped))
        #expect(simulated.state.highlight == nil)
        #expect(simulated.state.stats == nil)
        #expect(simulated.state.tab == .club)
        #expect(simulated.state.currentWeekIsInTheTable)
        #expect(simulated.state.playedHomeScore != nil)
        #expect(simulated.state.playedAwayScore != nil)
        #expect(simulated.state.standings.allSatisfy { $0.played == 1 })
        #expect(simulated.state.scorelines.count == 10)

        await simulated.send(.view(.leadersButtonTapped))
        #expect(simulated.state.leaders?.userClubID == "manchester-city")

        let kicked = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 7 }
        }
        kicked.exhaustivity = .off
        await kicked.send(.view(.kickOffButtonTapped))
        await kicked.send(.highlight(.presented(.view(.skipButtonTapped))))
        await kicked.send(.highlight(.presented(.view(.backButtonTapped))))
        await kicked.skipReceivedActions()
        #expect(kicked.state.standings == simulated.state.standings)
        #expect(kicked.state.playedHomeScore == simulated.state.playedHomeScore)
        #expect(kicked.state.playedAwayScore == simulated.state.playedAwayScore)
        #expect(kicked.state.scorelines == simulated.state.scorelines)
    }

    @Test func simulateSeasonAsksThenFinishesTheRemainingWeeks() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 11 }
        }
        store.exhaustivity = .off

        await store.send(.view(.simulateSeasonButtonTapped))
        #expect(store.state.seasonAlert != nil)
        #expect(store.state.seasonIsOver == false)
        await store.send(.seasonAlert(.dismiss))
        #expect(store.state.seasonAlert == nil)
        #expect(store.state.record == nil)
        #expect(store.state.weekIndex == 0)

        await store.send(.view(.simulateMatchButtonTapped))
        let afterOne = try #require(store.state.standings.first { $0.clubID == "manchester-city" })
        #expect(afterOne.played == 1)

        await store.send(.view(.simulateSeasonButtonTapped))
        await store.send(.seasonAlert(.presented(.confirm)))
        #expect(store.state.seasonAlert == nil)
        #expect(store.state.seasonIsOver)
        #expect(store.state.weekIndex == 37)
        #expect(store.state.hasNextFixture == false)
        #expect(store.state.highlight == nil)
        #expect(store.state.stats == nil)
        #expect(store.state.tab == .club)
        #expect(store.state.standings.allSatisfy { $0.played == 38 })
        #expect(store.state.record?.awards.map(\.kind) == AwardKind.allCases)
        let afterSeason = try #require(store.state.standings.first { $0.clubID == "manchester-city" })
        #expect(afterSeason.points >= afterOne.points)

        let fresh = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 11 }
        }
        fresh.exhaustivity = .off
        await fresh.send(.view(.simulateSeasonButtonTapped))
        await fresh.send(.seasonAlert(.presented(.confirm)))
        #expect(fresh.state.standings == store.state.standings)
        #expect(fresh.state.record == store.state.record)
    }

    @Test func aTableRowPushesTheSameTeamScreen() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        }
        let city = try #require(store.state.userClub)
        let other = try #require(store.state.clubs.first { $0.id != city.id })

        await store.send(.view(.teamButtonTapped(city.id))) {
            $0.team = TeamFeature.State(club: city, played: 0, points: 0, goalDifference: 0)
        }
        let cityPlayer = try #require(city.starters.first)
        await store.send(.team(.presented(.view(.playerTapped(cityPlayer.id))))) {
            $0.team?.player = PlayerDetailFeature.State(player: cityPlayer, clubName: city.name)
        }
        await store.send(.team(.presented(.player(.dismiss)))) {
            $0.team?.player = nil
        }
        await store.send(.team(.dismiss)) {
            $0.team = nil
        }

        await store.send(.view(.teamButtonTapped(other.id))) {
            $0.team = TeamFeature.State(club: other, played: 0, points: 0, goalDifference: 0)
        }
        #expect(store.state.team?.club.name == other.name)
        await store.send(.view(.teamButtonTapped("missing")))
        #expect(store.state.team?.club.id == other.id)
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

private func listedShots(_ shots: [Shot]) -> [Shot] {
    shots.enumerated()
        .filter { $0.element.result != .miss }
        .sorted { lhs, rhs in
            if lhs.element.minute != rhs.element.minute {
                return lhs.element.minute < rhs.element.minute
            }
            return lhs.offset < rhs.offset
        }
        .map(\.element)
}

@Suite
@MainActor
struct LeadersListTests {
    @Test func eachBoardStartsWithTenAndCanExpand() async {
        let season = LeagueDraft.makeLeague(seed: 1)
        let players = Array(season.clubs.flatMap(\.starters).prefix(12))
        let rows = players.enumerated().map { index, player in
            LeagueLeaders.Row(player: player, clubID: player.id.hasPrefix("manchester-city") ? "manchester-city" : "other", clubName: "Club", count: 30 - index)
        }
        let store = TestStore(
            initialState: LeadersFeature.State(goals: rows, assists: rows, saves: [], userClubID: "manchester-city")
        ) {
            LeadersFeature()
        }
        #expect(store.state.listedGoals.count == 10)
        #expect(store.state.goalsCanExpand)
        #expect(store.state.listedAssists.count == 10)
        #expect(store.state.savesCanExpand == false)
        await store.send(.view(.expandGoalsTapped)) {
            $0.goalsExpanded = true
        }
        #expect(store.state.listedGoals.count == 12)
        #expect(store.state.goalsCanExpand == false)
        #expect(store.state.listedAssists.count == 10)
    }
}
