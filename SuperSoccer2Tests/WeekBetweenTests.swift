import ComposableArchitecture
import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct WeekBetweenTests {
    @Test func aLongRunOfStartsMovesGreenToYellowThenRedAndOneBenchRecovers() throws {
        let tuning = WeekTuning.current
        var player = squadPlayer(id: "runner", position: .forward)
        #expect(player.fitnessBand() == .green)

        var month = player
        for _ in 0..<4 {
            month = WeekBetween.afterStart(month, tuning: tuning)
        }
        #expect(month.fitnessBand() == .green)
        #expect(player.condition - month.condition == tuning.fitnessLossPerStart * 4)

        var firstYellow: Int?
        var firstRed: Int?
        var sawYellow = false
        for week in 1...40 {
            player = WeekBetween.afterStart(player, tuning: tuning)
            switch player.fitnessBand(tuning: tuning) {
            case .green:
                #expect(sawYellow == false)
            case .yellow:
                sawYellow = true
                if firstYellow == nil { firstYellow = week }
            case .red:
                firstRed = week
            }
            if firstRed != nil { break }
        }

        let yellowWeek = try #require(firstYellow)
        let redWeek = try #require(firstRed)
        #expect(yellowWeek > 4)
        #expect(redWeek > yellowWeek)
        let debt = 100 - player.condition
        let rested = WeekBetween.afterBench(player, tuning: tuning)
        #expect(rested.condition - player.condition == tuning.benchRecovery)
        #expect(tuning.benchRecovery * 2 > debt)
        #expect(rested.fitnessBand(tuning: tuning) == .green)
    }

    @Test func aWeekCanAwardNoSkillsAndMoreThanOne() throws {
        var tuning = WeekTuning.current
        tuning.injuryChanceGreen = 0
        tuning.injuryChanceYellow = 0
        tuning.injuryChanceRed = 0
        let quiet = try settledSkills(xp: 0, tuning: tuning)
        #expect(quiet.offers.isEmpty)
        let quietUser = try #require(quiet.clubs.first { $0.id == "user" })
        #expect(quietUser.starters.allSatisfy { $0.xp == tuning.xpForStart })
        #expect(quietUser.players.allSatisfy { $0.skillsEarned == 0 })

        let busy = try settledSkills(xp: tuning.xpForFirstSkill - tuning.xpForStart, tuning: tuning)
        let userOffers = busy.offers.filter { $0.clubID == "user" }
        #expect(userOffers.count > 1)
        let user = try #require(busy.clubs.first { $0.id == "user" })
        let earned = user.players.filter { player in userOffers.contains { $0.playerID == player.id } }
        #expect(earned.count > 1)
        #expect(earned.allSatisfy { $0.skillsEarned == 0 })
        let forward = try #require(user.players.first { $0.id == "user-forward" })
        #expect(forward.ratings.shooting == 70)

        let other = try #require(busy.clubs.first { $0.id == "other" })
        let otherForward = try #require(other.players.first { $0.id == "other-forward" })
        #expect(otherForward.skillsEarned == 1)
        #expect(otherForward.ratings.shooting == 70 + tuning.skillPointsShooting)
        #expect(busy.offers.allSatisfy { $0.clubID == "user" })
    }

    @Test func anInjuryIsALineAndTheNextFitPlayerStepsIn() throws {
        var tuning = WeekTuning.current
        tuning.injuryChanceGreen = 0
        tuning.injuryChanceYellow = 0
        tuning.injuryChanceRed = 100
        let hurt = squadPlayer(id: "hurt", position: .defender, condition: tuning.yellowMinimum - 1, starter: true)
        let cover = squadPlayer(id: "cover", position: .defender, starter: false)
        let keeper = squadPlayer(id: "keeper", position: .keeper, starter: true)
        let side = sampleClub(id: "user", players: [keeper, hurt, cover])
        let opponent = sampleClub(id: "other", players: [squadPlayer(id: "away-keeper", position: .keeper, starter: true)])
        let settlement = WeekBetween.settle(
            clubs: [side, opponent],
            scorelines: [Matchweek.Scoreline(homeID: "user", awayID: "other", homeScore: 1, awayScore: 1)],
            tallies: [],
            userClubID: "user",
            seed: 7,
            tuning: tuning
        )
        let club = try #require(settlement.clubs.first { $0.id == "user" })
        #expect(club.injuryLines.contains { $0.contains("Bo Queef") && $0.contains("is out") })
        #expect(club.starters.contains { $0.id == "cover" })
        #expect(club.starters.contains { $0.id == "hurt" } == false)
        #expect(club.players.first { $0.id == "hurt" }?.injury != nil)
    }

    @Test func otherClubsRestOneTiredPlayerAndLeaveAGreenSideAlone() throws {
        let tuning = WeekTuning.current
        let green = lineOfPlayers(idPrefix: "green", condition: 100)
        #expect(WeekBetween.restOneTired(green, tuning: tuning).starters.map(\.id) == green.starters.map(\.id))

        var tired = lineOfPlayers(idPrefix: "tired", condition: 100)
        tired.players = tired.players.map { player in
            var copy = player
            if copy.isStarter, copy.position == .defender { copy.condition = tuning.yellowMinimum - 1 }
            return copy
        }
        let before = Set(tired.starters.map(\.id))
        let rested = WeekBetween.restOneTired(tired, tuning: tuning)
        let sat = before.subtracting(Set(rested.starters.map(\.id)))
        #expect(sat.count == 1)
        let satID = try #require(sat.first)
        #expect(tired.players.first { $0.id == satID }?.fitnessBand(tuning: tuning) == .red)

        var safe = WeekTuning.current
        safe.injuryChanceGreen = 0
        safe.injuryChanceYellow = 0
        safe.injuryChanceRed = 0
        let user = lineOfPlayers(idPrefix: "user", condition: tuning.yellowMinimum - 1)
        let other = lineOfPlayers(idPrefix: "other", condition: tuning.yellowMinimum - 1)
        let userStarters = Set(user.starters.map(\.id))
        let settlement = WeekBetween.settle(
            clubs: [user, other],
            scorelines: [Matchweek.Scoreline(homeID: "user", awayID: "other", homeScore: 0, awayScore: 0)],
            tallies: [],
            userClubID: "user",
            seed: 3,
            tuning: safe
        )
        let userAfter = try #require(settlement.clubs.first { $0.id == "user" })
        let otherAfter = try #require(settlement.clubs.first { $0.id == "other" })
        #expect(Set(userAfter.starters.map(\.id)) == userStarters)
        let otherBefore = Set(other.starters.map(\.id))
        #expect(otherBefore.subtracting(Set(otherAfter.starters.map(\.id))).count == 1)
    }

    @Test func tiredOrMissingPlayersChangeTheScore() {
        let pair = SquadCatalog.makePair(seed: 42)
        let city = pair[0]
        let norwich = pair[1]
        var tired = city
        tired.players = city.players.map { player in
            var copy = player
            if copy.isStarter { copy.condition = WeekTuning.current.yellowMinimum }
            return copy
        }
        #expect(tired.attack < city.attack)
        #expect(tired.defense < city.defense)
        #expect(scoreChanges(home: city, otherHome: tired, away: norwich))

        let starter = city.starters.filter { $0.position == .forward }.max { $0.overall < $1.overall }!
        let cover = city.bench.filter { $0.position == .forward }.min { $0.overall < $1.overall }!
        let missing = WeekBetween.replace(starter.id, with: cover.id, in: city)!
        #expect(missing.starters.contains { $0.id == starter.id } == false)
        #expect(scoreChanges(home: city, otherHome: missing, away: norwich))
    }

    @Test func swappingTheXIChangesWhoPlays() throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let city = try #require(season.clubs.first { $0.id == "manchester-city" })
        let opponent = try #require(season.clubs.first { $0.id != city.id })
        let starter = try #require(city.starters.first { $0.position == .forward })
        let incoming = try #require(WeekBetween.bestFit(replacing: starter, in: city.players))
        let swapped = try #require(WeekBetween.replace(starter.id, with: incoming.id, in: city))
        #expect(swapped.starters.contains { $0.id == incoming.id })
        #expect(swapped.starters.contains { $0.id == starter.id } == false)

        let match = MatchSimulator.simulate(home: swapped, away: opponent, seed: 3)
        let playing = Set(swapped.starters.map(\.id))
        let homeShots = match.shots.filter(\.isHome)
        #expect(homeShots.isEmpty == false)
        for shot in homeShots {
            #expect(playing.contains(shot.shooter.id))
            if let passer = shot.passer {
                #expect(playing.contains(passer.id))
            }
            #expect(shot.shooter.id != starter.id)
        }
    }
}

@Suite
@MainActor
struct WeekBetweenFeatureTests {
    @Test func restingAStarterChangesWhoKicksOff() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let store = TestStore(initialState: MatchweekFeature.State(userClubID: "manchester-city", season: season)) {
            MatchweekFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 5 }
        }
        store.exhaustivity = .off

        let club = try #require(store.state.userClub)
        let starter = try #require(club.starters.first { WeekBetween.bestFit(replacing: $0, in: club.players) != nil })
        let incoming = try #require(WeekBetween.bestFit(replacing: starter, in: club.players))
        await store.send(.view(.restStarter(starter.id)))
        let after = try #require(store.state.userClub)
        #expect(after.starters.contains { $0.id == starter.id } == false)
        #expect(after.starters.contains { $0.id == incoming.id })

        await store.send(.view(.simulateMatchButtonTapped))
        let pending = try #require(store.state.pending)
        let played = pending.home.id == club.id ? pending.home : pending.away
        let playing = Set(played.starters.map(\.id))
        #expect(playing.contains(incoming.id))
        #expect(playing.contains(starter.id) == false)
        let userIsHome = pending.home.id == club.id
        for shot in pending.userMatch.shots where shot.isHome == userIsHome {
            #expect(playing.contains(shot.shooter.id))
        }
    }
}

private func settledSkills(xp: Int, tuning: WeekTuning) throws -> WeekBetween.Settlement {
    let userForward = squadPlayer(id: "user-forward", position: .forward, starter: true, xp: xp)
    let userMid = squadPlayer(id: "user-mid", position: .midfielder, starter: true, xp: xp)
    let userKeeper = squadPlayer(id: "user-keeper", position: .keeper, starter: true, xp: 0)
    let otherForward = squadPlayer(id: "other-forward", position: .forward, starter: true, xp: xp)
    let otherKeeper = squadPlayer(id: "other-keeper", position: .keeper, starter: true, xp: 0)
    return WeekBetween.settle(
        clubs: [
            sampleClub(id: "user", players: [userKeeper, userForward, userMid]),
            sampleClub(id: "other", players: [otherKeeper, otherForward]),
        ],
        scorelines: [Matchweek.Scoreline(homeID: "user", awayID: "other", homeScore: 1, awayScore: 1)],
        tallies: [],
        userClubID: "user",
        seed: 11,
        tuning: tuning
    )
}

/// One starter and one green reserve in each outfield role, plus two keepers.
private func lineOfPlayers(idPrefix: String, condition: Int) -> Club {
    var players: [Player] = []
    players.append(squadPlayer(id: "\(idPrefix)-gk-s", position: .keeper, condition: 100, starter: true))
    players.append(squadPlayer(id: "\(idPrefix)-gk-b", position: .keeper, condition: 100, starter: false))
    for position in [Position.defender, .midfielder, .forward] {
        for index in 0..<3 {
            players.append(
                squadPlayer(
                    id: "\(idPrefix)-\(position.label)-\(index)",
                    position: position,
                    condition: condition,
                    starter: true
                )
            )
        }
        players.append(
            squadPlayer(
                id: "\(idPrefix)-\(position.label)-bench",
                position: position,
                condition: 100,
                starter: false
            )
        )
    }
    return sampleClub(id: idPrefix, players: players)
}

private func sampleClub(id: String, players: [Player]) -> Club {
    Club(
        id: id,
        name: id,
        shortName: "TST",
        listName: id,
        nickname: "Testers",
        kit: Kit(
            primary: KitColor(red: 0, green: 0, blue: 0),
            secondary: KitColor(red: 1, green: 1, blue: 1)
        ),
        players: players
    )
}

private func squadPlayer(
    id: String,
    position: Position,
    condition: Int = 100,
    starter: Bool = false,
    xp: Int = 0
) -> Player {
    var player = Player(
        id: id,
        firstName: "Bo",
        lastName: "Queef",
        position: position,
        condition: condition,
        ratings: Ratings(speed: 70, shooting: 70, passing: 70, dribbling: 70, defending: 70, goalkeeping: 70)
    )
    player.isStarter = starter
    player.xp = xp
    return player
}

private func scoreChanges(home: Club, otherHome: Club, away: Club) -> Bool {
    for seed in UInt64(1)...40 {
        let fresh = MatchSimulator.simulate(home: home, away: away, seed: seed)
        let changed = MatchSimulator.simulate(home: otherHome, away: away, seed: seed)
        if fresh.homeScore != changed.homeScore || fresh.awayScore != changed.awayScore {
            return true
        }
    }
    return false
}
