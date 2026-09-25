import ComposableArchitecture
import CryptoKit
import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct NameAndSquadTests {
    @Test func nameListMatchesThePreviousApp() {
        #expect(NameGenerator.names.count == 449)
        #expect(NameGenerator.names.first == "Bo")
        #expect(NameGenerator.names.last == "Orlando")
        #expect(NameGenerator.names.filter { $0 == "Bruce" }.count == 2)
        #expect(NameGenerator.names.filter { $0 == "Wesley" }.count == 2)
        #expect(NameGenerator.names.filter { $0 == "Phillips" }.count == 2)
        for joke in ["Queef", "Chode", "Scaramucci", "Pistacio", "Buckwalter", "Magnusson"] {
            #expect(NameGenerator.names.contains(joke))
        }
        let digest = SHA256.hash(data: Data(NameGenerator.names.joined(separator: "\n").utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        #expect(hex == "ffc801a8e81cd9ae03c094aac6296e8d2e7f40b592ceaeb33e86bce215e47787")
    }

    @Test func generationCanBlankAFirstNameAndAppendASuffix() {
        var sawBlank = false
        var sawSuffix = false
        for seed in UInt64(1)...400 {
            var generator = SeededGenerator(seed: seed)
            for _ in 0..<30 {
                let first = NameGenerator.makeFirstName(using: &generator)
                let last = NameGenerator.makeLastName(using: &generator)
                if first.isEmpty { sawBlank = true }
                if last.contains(" Sr.") || last.contains(" Jr.") || last.contains(" III") || last.contains(" IV") {
                    sawSuffix = true
                }
            }
            if sawBlank, sawSuffix { break }
        }
        #expect(sawBlank)
        #expect(sawSuffix)
    }

    @Test func blankFirstNameUsesTheSurnameAlone() {
        let player = makePlayer(first: "", last: "Queef", position: .forward)
        #expect(player.fullName == "Queef")
    }

    @Test func squadsAreStableForASeed() {
        let first = SquadCatalog.makePair(seed: 42)
        let second = SquadCatalog.makePair(seed: 42)
        #expect(first == second)
        #expect(first[0].name == "Manchester City")
        #expect(first[1].name == "Norwich City")
        #expect(first[0].starters.count == 11)
        #expect(first[0].starters.filter { $0.position == .keeper }.count == 1)
    }

    @Test func teamOverallIsTheMeanOfAttackAndDefense() {
        #expect(Club.overall(attack: 92, defense: 79) == 86)
        #expect(Club.overall(attack: 71, defense: 68) == 70)
        #expect(Club.overall(attack: 0, defense: 0) == 1)
        #expect(Club.overall(attack: 200, defense: 200) == 99)
        #expect(Club.overall(attack: 80, defense: 81) == 81)
        #expect(Club.overall(attack: 80, defense: 83) == 82)

        let clubs = SquadCatalog.makePair(seed: 42)
        let city = clubs[0]
        let norwich = clubs[1]
        #expect(city.overall == Club.overall(attack: city.attack, defense: city.defense))
        #expect(norwich.overall == Club.overall(attack: norwich.attack, defense: norwich.defense))
        #expect(city.attack == 92)
        #expect(city.defense == 79)
        #expect(norwich.attack == 71)
        #expect(norwich.defense == 68)
        let playerMean = city.starters.reduce(0) { $0 + $1.overall } / city.starters.count
        #expect(city.overall != playerMean)
    }

    @Test func aNewSeedRollsANewSquad() {
        let first = SquadCatalog.makePair(seed: 1)
        let second = SquadCatalog.makePair(seed: 2)
        #expect(first != second)
        #expect(first[0].overall != 69 || first[1].overall != 62)
    }

    @Test func cityIsTheClearFavoriteAndNorwichCanStillScore() {
        let clubs = SquadCatalog.makePair(seed: 42)
        let city = clubs[0]
        let norwich = clubs[1]
        #expect(city.attack > norwich.attack)
        #expect(city.defense > norwich.defense)
        #expect(city.overall > norwich.overall)
        let tuning = MatchTuning.current
        let homeMean = tuning.mean(attack: city.attack, defense: norwich.defense, home: true)
        let awayMean = tuning.mean(attack: norwich.attack, defense: city.defense, home: false)
        #expect(homeMean > awayMean)
        var norwichGoals = 0
        for seed in UInt64(1)...400 {
            norwichGoals += MatchSimulator.simulate(home: city, away: norwich, seed: seed).awayScore
        }
        #expect(norwichGoals > 0)
    }
}

@Suite
struct MatchSimulatorTests {
    @Test func sameSeedRepeatsTheMatch() {
        let clubs = SquadCatalog.makePair(seed: 7)
        let first = MatchSimulator.simulate(home: clubs[0], away: clubs[1], seed: 99)
        let second = MatchSimulator.simulate(home: clubs[0], away: clubs[1], seed: 99)
        #expect(first == second)
    }

    @Test func eachSideHasAShot() {
        let clubs = SquadCatalog.makePair(seed: 3)
        for seed: UInt64 in [1, 2, 8, 99, 2024] {
            let match = MatchSimulator.simulate(home: clubs[0], away: clubs[1], seed: seed)
            #expect(match.shots.contains { $0.isHome })
            #expect(match.shots.contains { !$0.isHome })
            #expect(match.homeScore >= 0)
            #expect(match.awayScore >= 0)
            if match.homeScore + match.awayScore == 0 {
                #expect(match.highlight.id == match.shots[0].id)
                #expect(match.highlight.result != .goal)
            } else {
                let firstGoal = match.shots.first { $0.result == .goal }
                #expect(match.highlight.id == firstGoal?.id)
            }
            let attacking = match.highlight.isHome ? clubs[0].name : clubs[1].name
            let defending = match.highlight.isHome ? clubs[1].name : clubs[0].name
            #expect(
                match.commentary == Commentary.line(
                    shot: match.highlight,
                    attackingClub: attacking,
                    defendingClub: defending
                )
            )
        }
    }

    @Test func nonPositiveScoringWeightIsSkipped() {
        let quiet = makePlayer(
            id: "quiet",
            position: .forward,
            ratings: Ratings(speed: 30, shooting: 20, passing: 30, dribbling: 20, defending: 20, goalkeeping: 10)
        )
        let loud = makePlayer(
            id: "loud",
            position: .forward,
            ratings: Ratings(speed: 80, shooting: 90, passing: 70, dribbling: 80, defending: 30, goalkeeping: 10)
        )
        #expect(quiet.scoring - 50 <= 0)
        #expect(loud.scoring - 50 > 0)
        var generator = SeededGenerator(seed: 5)
        for _ in 0..<25 {
            let picked = MatchSimulator.pickScorer(from: [quiet, loud], using: &generator)
            #expect(picked.id == "loud")
        }
    }

    @Test func highlightPrefersTheFirstGoal() {
        let earlyMiss = makeShot(id: 0, minute: 4, result: .miss)
        let laterGoal = makeShot(id: 1, minute: 12, result: .goal)
        let picked = MatchSimulator.highlightShot(in: [earlyMiss, laterGoal], homeScore: 1, awayScore: 0)
        #expect(picked.id == 1)
        let blank = MatchSimulator.highlightShot(in: [earlyMiss, laterGoal], homeScore: 0, awayScore: 0)
        #expect(blank.id == 0)
    }

    @Test func pinnedSeedNamesTheRoll() {
        let clubs = SquadCatalog.makePair(seed: 42)
        let match = MatchSimulator.simulate(home: clubs[0], away: clubs[1], seed: 42)
        let passer = match.highlight.passer?.fullName ?? "-"
        let summary = """
        \(match.homeScore)-\(match.awayScore)
        \(match.highlight.shooter.fullName)
        \(passer)
        \(match.highlight.keeper.fullName)
        \(match.highlight.result.rawValue)
        \(match.highlight.type.rawValue)
        \(match.highlight.minute)
        \(match.commentary)
        names \(clubs[0].starters[0].fullName) | \(clubs[1].starters[10].fullName)
        """
        #expect(summary == pinnedSeedSummary)
    }
}

@Suite
struct CommentaryTests {
    @Test func goalWithPasserAndPenalty() {
        let shot = makeShot(
            result: .goal,
            type: .penalty,
            shooter: "Bo Scaramucci",
            passer: "Chode Magnusson"
        )
        let line = Commentary.line(shot: shot, attackingClub: "Manchester City", defendingClub: "Norwich City")
        #expect(line == "Penalty. Bo Scaramucci of Manchester City scores from Chode Magnusson.")
    }

    @Test func saveNamesTheKeeper() {
        let shot = makeShot(result: .save, shooter: "Queef Pistacio", keeper: "Udder Quartz")
        let line = Commentary.line(shot: shot, attackingClub: "Norwich City", defendingClub: "Manchester City")
        #expect(line == "Queef Pistacio of Norwich City shoots. Udder Quartz saves for Manchester City.")
    }

    @Test func missWithPasser() {
        let shot = makeShot(result: .miss, shooter: "Foo Bar", passer: "Hank Buckwalter")
        let line = Commentary.line(shot: shot, attackingClub: "Manchester City", defendingClub: "Norwich City")
        #expect(line == "Hank Buckwalter finds Foo Bar of Manchester City, who misses.")
    }
}

@Suite
@MainActor
struct HighlightFeatureTests {
    @Test func beatRevealsTheSentenceOnTheClock() async {
        let clock = TestClock()
        let store = TestStore(initialState: HighlightFeature.State(match: sampleMatch(), home: sampleHome(), away: sampleAway())) {
            HighlightFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.onAppear(reduceMotion: false)))
        await clock.advance(by: HighlightFeature.beatDuration)
        await store.receive(\.view.advance) {
            $0.ballProgress = 1
            $0.sentenceVisible = true
        }
    }

    @Test func reduceMotionShowsTheLineImmediately() async {
        let store = TestStore(initialState: HighlightFeature.State(match: sampleMatch(), home: sampleHome(), away: sampleAway())) {
            HighlightFeature()
        }

        await store.send(.view(.onAppear(reduceMotion: true))) {
            $0.ballProgress = 1
            $0.sentenceVisible = true
        }
    }

    @Test func leavingCancelsTheBeat() async {
        let clock = TestClock()
        let store = TestStore(initialState: HighlightFeature.State(match: sampleMatch(), home: sampleHome(), away: sampleAway())) {
            HighlightFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.onAppear(reduceMotion: false)))
        await store.send(.view(.backButtonTapped))
        await store.receive(\.delegate.dismissed)
    }
}

@Suite
@MainActor
struct AppFeatureTests {
    @Test func pickKickoffAndReturnKeepsTheScore() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 42 }
        }
        store.exhaustivity = .off

        await store.send(.selection(.view(.onAppear)))
        #expect(store.state.selection.clubs.map(\.name) == ["Manchester City", "Norwich City"])

        await store.send(.selection(.view(.clubTapped("norwich-city"))))
        await store.skipReceivedActions()
        guard let pathID = store.state.path.ids.first else {
            Issue.record("Matchday was not pushed")
            return
        }
        let matchday = store.state.path[id: pathID, case: \.matchday]
        #expect(matchday?.userClub.name == "Norwich City")
        #expect(matchday?.opponent.name == "Manchester City")

        await store.send(.path(.element(id: pathID, action: .matchday(.view(.kickOffButtonTapped)))))
        let played = store.state.path[id: pathID, case: \.matchday]
        #expect(played?.result != nil)
        #expect(played?.highlight?.commentary == played?.result?.commentary)
        #expect(played?.highlight?.sentenceVisible == false)
        #expect(played?.result?.commentary.contains("of ") == true)

        await store.send(.path(.element(
            id: pathID,
            action: .matchday(.highlight(.presented(.view(.backButtonTapped))))
        )))
        await store.skipReceivedActions()
        let returned = store.state.path[id: pathID, case: \.matchday]
        #expect(returned?.highlight == nil)
        #expect(returned?.result == played?.result)
    }
}

private let pinnedSeedSummary = """
5-0
Dick Ruben
Elijah Gary
Lopez Vargas
goal
regular
4
Dick Ruben of Manchester City scores from Elijah Gary.
names Darrius Christopher | Chestnutt Gus
"""

private func makePlayer(
    id: String = "p",
    first: String = "Bo",
    last: String = "Queef",
    position: Position = .forward,
    ratings: Ratings = Ratings(speed: 70, shooting: 70, passing: 70, dribbling: 70, defending: 40, goalkeeping: 10)
) -> Player {
    Player(id: id, firstName: first, lastName: last, position: position, condition: 100, ratings: ratings)
}

private func named(_ full: String, id: String, position: Position = .forward) -> Player {
    let parts = full.split(separator: " ", maxSplits: 1).map(String.init)
    return makePlayer(id: id, first: parts[0], last: parts.count > 1 ? parts[1] : "", position: position)
}

private func makeShot(
    id: Int = 0,
    minute: Int = 12,
    result: ShotResult,
    type: ShotType = .regular,
    shooter: String = "Bo Queef",
    passer: String? = nil,
    keeper: String = "Hank Keeper"
) -> Shot {
    Shot(
        id: id,
        type: type,
        result: result,
        shooter: named(shooter, id: "shooter"),
        passer: passer.map { named($0, id: "passer", position: .midfielder) },
        keeper: named(keeper, id: "keeper", position: .keeper),
        minute: minute,
        isHome: true
    )
}

private func sampleHome() -> Club {
    SquadCatalog.makePair(seed: 1)[0]
}

private func sampleAway() -> Club {
    SquadCatalog.makePair(seed: 1)[1]
}

private func sampleMatch() -> MatchResult {
    let shot = makeShot(result: .goal, shooter: "Bo Scaramucci", passer: "Chode Magnusson")
    return MatchResult(
        homeScore: 2,
        awayScore: 0,
        shots: [shot],
        highlight: shot,
        commentary: Commentary.line(shot: shot, attackingClub: "Manchester City", defendingClub: "Norwich City"),
        seed: 1
    )
}
