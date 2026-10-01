import AVFoundation
import ComposableArchitecture
import Foundation
import os
import Testing
@testable import SuperSoccer2

@Suite
struct RatingTrackTests {
    @Test func ninetyDegradedToEightyFillsEightUnitsAndMarksTheNinth() {
        let track = RatingTrack.fitness(full: 90, current: 80, potential: 99)
        #expect(track.filledPoints / RatingTrack.pointsPerUnit == 8)
        #expect(track.markedPoints / RatingTrack.pointsPerUnit == 1)
        #expect(track.emptyPoints == 9)
        #expect(track.ceiling == 99)
        #expect(track.filledPoints + track.markedPoints + track.emptyPoints == track.ceiling)
    }

    @Test func conditionUsesTheWeekScale() {
        var player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: WeekTuning.current.yellowMinimum,
            isStarter: true,
            ratings: Ratings(speed: 90, shooting: 80, passing: 70, dribbling: 60, defending: 50, goalkeeping: 40)
        )
        let scale = WeekTuning.current.ratingScaleYellow
        let current = player.playingRating(.speed)
        #expect(player.fitnessBand() == .yellow)
        #expect(current == Int(Double(90) * scale))
        #expect(current < 90)
        let track = RatingTrack.fitness(full: 90, current: current, potential: 96)
        #expect(track.filledPoints == current)
        #expect(track.markedPoints == 90 - current)
        #expect(track.emptyPoints == 6)
        #expect(track.ceiling == 96)

        player.condition = WeekTuning.current.greenMinimum
        #expect(player.playingRating(.speed) == 90)
        let full = RatingTrack.fitness(full: 90, current: player.playingRating(.speed), potential: 96)
        #expect(full.markedPoints == 0)
        #expect(full.filledPoints == 90)
        #expect(full.ceiling == 96)
    }

    @Test func aSkillShowsTheTuningBoostAndStopsAt99() {
        let shooting = WeekTuning.current.points(for: .shooting)
        let defending = WeekTuning.current.points(for: .defending)
        #expect(shooting == WeekTuning.current.skillPointsShooting)
        #expect(defending == WeekTuning.current.skillPointsDefending)
        #expect(shooting != defending)

        let grown = SkillProjection.make(current: 80, boost: shooting)
        #expect(grown.reading == "80→85")
        #expect(grown.available)
        #expect(RatingTrack.growth(grown).markedPoints == shooting)

        let role = SkillProjection.make(current: 80, boost: defending)
        #expect(role.reading == "80→\(80 + defending)")
        #expect(RatingTrack.growth(role).markedPoints == defending)

        let capped = SkillProjection.make(current: 97, boost: shooting)
        #expect(capped.reading == "97→99")
        #expect(capped.available)
        #expect(RatingTrack.growth(capped).markedPoints == 2)
        #expect(RatingTrack.growth(capped).emptyPoints == 0)
        #expect(RatingTrack.growth(capped).ceiling == 99)
        #expect(RatingTrack.trackPoints - RatingTrack.growth(capped).ceiling == 1)

        let full = SkillProjection.make(current: 99, boost: shooting)
        #expect(full.available == false)
        #expect(full.reading == "99")
        #expect(full.next == 99)
        #expect(RatingTrack.growth(full).markedPoints == 0)
    }

    @Test func theTrackEndsAtPotentialAndTheSameRatingFillsTheSameLength() {
        let shorter = RatingTrack.fitness(full: 80, current: 80, potential: 85)
        let longer = RatingTrack.fitness(full: 80, current: 80, potential: 96)
        #expect(shorter.filledPoints == longer.filledPoints)
        #expect(shorter.filledPoints == 80)
        #expect(longer.ceiling > shorter.ceiling)
        #expect(shorter.ceiling == 85)
        #expect(longer.ceiling == 96)
        #expect(shorter.filledPoints + shorter.markedPoints + shorter.emptyPoints == shorter.ceiling)
        #expect(longer.filledPoints + longer.markedPoints + longer.emptyPoints == longer.ceiling)

        let tight = SkillProjection.make(current: 80, boost: 5, ceiling: 82)
        #expect(tight.reading == "80→82")
        #expect(tight.available)
        let preview = RatingTrack.growth(tight)
        #expect(preview.markedPoints == 2)
        #expect(preview.emptyPoints == 0)
        #expect(preview.filledPoints + preview.markedPoints <= preview.ceiling)

        let roomy = SkillProjection.make(current: 80, boost: 5, ceiling: 88)
        let inside = RatingTrack.growth(roomy)
        #expect(roomy.next == 85)
        #expect(inside.markedPoints == 5)
        #expect(inside.emptyPoints == 3)
        #expect(inside.ceiling == 88)
        #expect(inside.filledPoints + inside.markedPoints + inside.emptyPoints == inside.ceiling)

        let done = SkillProjection.make(current: 80, boost: 5, ceiling: 80)
        #expect(done.available == false)
        #expect(done.reading == "80")
        #expect(done.next == 80)
    }

    @Test func growthAndConditionStayInsideOneTrack() {
        let tired = RatingTrack.fitness(full: 90, current: 80, potential: 99)
        let growing = RatingTrack.growth(SkillProjection.make(current: 80, boost: 5))
        #expect(tired.filledPoints + tired.markedPoints + tired.emptyPoints == tired.ceiling)
        #expect(growing.filledPoints + growing.markedPoints + growing.emptyPoints == growing.ceiling)
        #expect(tired.filledPoints == 80)
        #expect(tired.markedPoints == 10)
        #expect(growing.filledPoints == 80)
        #expect(growing.markedPoints == 5)
        let early = RatingTrack.experience(current: 40, required: 100)
        let later = RatingTrack.experience(current: 40, required: 140)
        #expect(early.markedPoints == 0)
        #expect(early.filledPoints + early.emptyPoints == RatingTrack.trackPoints)
        #expect(early.filledPoints == 40)
        #expect(later.filledPoints < early.filledPoints)
        #expect(later.filledPoints == Int((40.0 / 140.0 * 100).rounded()))
        let progress = ExperienceProgress.make(
            player: Player(
                id: "p",
                firstName: "Ada",
                lastName: "Ball",
                position: .forward,
                condition: 100,
                ratings: Ratings(speed: 70, shooting: 70, passing: 70, dribbling: 70, defending: 70, goalkeeping: 70),
                xp: 40,
                level: 1
            )
        )
        #expect(progress.required == 110)
        #expect(progress.remaining == 70)
        #expect(progress.reading == "40/110")
        #expect(GrowthReading.widest == "90→99")
        #expect(GrowthReading.widest.count == SkillProjection.make(current: 80, boost: 5).reading.count)
    }
}

@Suite
@MainActor
struct SkillChoiceLimitTests {
    @Test func aStatAt99CannotBeChosen() async throws {
        let player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: 100,
            ratings: Ratings(speed: 80, shooting: 99, passing: 70, dribbling: 80, defending: 97, goalkeeping: 40)
        )
        let clock = TestClock()
        let store = skillStore(player: player, clock: clock)

        await store.send(.view(.statTapped(.shooting, reduceMotion: false)))
        let defending = try #require(WeekTuning.current.skillChoices.first { $0.stat == .defending })
        let projection = SkillProjection.make(current: 97, boost: defending.points, ceiling: player.potential.defending)
        #expect(projection.reading == "97→99")
        await store.send(.view(.statTapped(.defending, reduceMotion: false))) {
            $0.selectedStat = .defending
            $0.phase = .selected
        }
        await clock.advance(by: SkillChoiceFeature.selectBeat)
        await store.receive(\.internal.grow) {
            $0.phase = .growing
        }
        await clock.advance(by: SkillChoiceFeature.growBeat)
        await store.receive(\.internal.grown) {
            $0.phase = .grown
        }
        await store.send(.view(.continueTapped))
        await store.receive(\.delegate.chose, .defending)
        await store.finish()
    }

    @Test func aStatAtItsCeilingCannotBeChosen() async throws {
        var player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: 100,
            ratings: Ratings(speed: 80, shooting: 70, passing: 70, dribbling: 80, defending: 60, goalkeeping: 40)
        )
        player.potential.shooting = 70
        let clock = TestClock()
        let store = skillStore(player: player, clock: clock)

        await store.send(.view(.statTapped(.shooting, reduceMotion: false)))
        let passing = try #require(WeekTuning.current.skillChoices.first { $0.stat == .passing })
        let projection = SkillProjection.make(
            current: 70,
            boost: passing.points,
            ceiling: player.potential.passing
        )
        #expect(projection.reading == "70→\(70 + passing.points)")
        await store.send(.view(.statTapped(.passing, reduceMotion: false))) {
            $0.selectedStat = .passing
            $0.phase = .selected
        }
        await store.send(.view(.continueTapped))
        await clock.advance(by: SkillChoiceFeature.selectBeat)
        await store.receive(\.internal.grow) {
            $0.phase = .growing
        }
        #expect(store.state.displayedOverall == player.overall)
        await clock.advance(by: SkillChoiceFeature.growBeat)
        await store.receive(\.internal.grown) {
            $0.phase = .grown
        }
        await store.send(.view(.continueTapped))
        await store.receive(\.delegate.chose, .passing)
        await store.finish()
    }

    @Test func theOverallMovesWhenTheBarFinishes() async throws {
        let player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: 100,
            ratings: Ratings(speed: 80, shooting: 70, passing: 70, dribbling: 70, defending: 50, goalkeeping: 40)
        )
        let points = WeekTuning.current.points(for: .shooting)
        var grown = player
        grown.ratings.shooting += points
        #expect(grown.overall != player.overall)
        #expect(SkillChoiceFeature.State(
            offerID: "offer",
            player: player,
            choices: WeekTuning.current.skillChoices
        ).displayedLevel == player.level + 1)
        let plays = OSAllocatedUnfairLock(initialState: 0)
        let clock = TestClock()
        let store = skillStore(player: player, clock: clock) {
            $0.levelUpSound.play = {
                plays.withLock { $0 += 1 }
                return
            }
        }

        #expect(store.state.displayedOverall == player.overall)
        #expect(store.state.reason == "Ada Ball was practicing late at night all week long.")
        #expect(store.state.instruction == "Pick one stat")
        await store.send(.view(.statTapped(.shooting, reduceMotion: false))) {
            $0.selectedStat = .shooting
            $0.phase = .selected
        }
        #expect(store.state.displayedOverall == player.overall)
        await store.send(.view(.statTapped(.passing, reduceMotion: false)))
        await clock.advance(by: SkillChoiceFeature.selectBeat)
        await store.receive(\.internal.grow) {
            $0.phase = .growing
        }
        #expect(store.state.displayedOverall == player.overall)
        await clock.advance(by: .milliseconds(519))
        #expect(store.state.phase == .growing)
        await clock.advance(by: .milliseconds(1))
        await store.receive(\.internal.grown) {
            $0.phase = .grown
        }
        #expect(plays.withLock { $0 } == 1)
        #expect(store.state.displayedOverall == grown.overall)
        #expect(store.state.instruction == "His Shooting has really improved.")
        #expect(store.state.player.ratings == player.ratings)
        await store.send(.view(.continueTapped))
        await store.receive(\.delegate.chose, .shooting)
        await store.finish()
    }

    @Test func theLevelUpSoundIsPreparedBeforeItPlays() async throws {
        let player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: 100,
            ratings: Ratings(speed: 80, shooting: 70, passing: 70, dribbling: 70, defending: 50, goalkeeping: 40)
        )
        let events = OSAllocatedUnfairLock(initialState: [String]())
        let clock = TestClock()
        let store = skillStore(player: player, clock: clock) {
            $0.levelUpSound.prepare = {
                events.withLock { $0.append("prepare") }
            }
            $0.levelUpSound.play = {
                events.withLock { $0.append("play") }
            }
        }

        await store.send(.view(.onAppear))
        #expect(events.withLock { $0 } == ["prepare"])
        await store.send(.view(.statTapped(.shooting, reduceMotion: false))) {
            $0.selectedStat = .shooting
            $0.phase = .selected
        }
        #expect(events.withLock { $0 } == ["prepare"])
        await clock.advance(by: SkillChoiceFeature.selectBeat)
        await store.receive(\.internal.grow) {
            $0.phase = .growing
        }
        #expect(events.withLock { $0 } == ["prepare", "play"])
        await clock.advance(by: SkillChoiceFeature.growBeat)
        await store.receive(\.internal.grown) {
            $0.phase = .grown
        }
        await store.finish()
    }

    @Test func reducedMotionStillWaitsToBeDismissed() async throws {
        let player = Player(
            id: "p",
            firstName: "Ada",
            lastName: "Ball",
            position: .forward,
            condition: 100,
            ratings: Ratings(speed: 80, shooting: 70, passing: 70, dribbling: 70, defending: 50, goalkeeping: 40)
        )
        let store = skillStore(player: player, clock: TestClock())
        await store.send(.view(.statTapped(.shooting, reduceMotion: true))) {
            $0.selectedStat = .shooting
            $0.phase = .grown
        }
        #expect(store.state.displayedOverall == store.state.overall(after: .shooting))
        await store.send(.view(.continueTapped))
        await store.receive(\.delegate.chose, .shooting)
        await store.finish()
    }
}

@Suite
struct LevelUpCopyTests {
    @Test func theOldLinesStayAndAnOfferKeepsItsSentence() {
        #expect(LevelUpCopy.lines.count == 20)
        #expect(LevelUpCopy.lines.contains("doesn't fuck around."))
        #expect(LevelUpCopy.lines.contains("ate a discarded fetus."))
        #expect(LevelUpCopy.lines.contains("discovered his inner bastard child."))
        #expect(LevelUpCopy.lines.contains("FINALLY got those genital warts removed!"))
        #expect(LevelUpCopy.line(for: "offer") == "was practicing late at night all week long.")
        #expect(LevelUpCopy.line(for: "offer-1") == "might have some real potential.")
        #expect(LevelUpCopy.sentence(name: "Ada Ball", offerID: "one") == "Ada Ball is turning into a stud.")
        #expect(SkillChoiceFeature.selectBeat == .milliseconds(280))
        #expect(SkillChoiceFeature.growBeat == .milliseconds(520))
        #expect(abs(SkillChoiceFeature.growSeconds - 0.52) < 0.000_001)
    }

    @Test @MainActor func theLevelUpSoundIsAShortClipInTheApp() throws {
        let bundle = try #require(Bundle(identifier: "dev.personal.SuperSoccer2"))
        let url = try #require(bundle.url(forResource: "LevelUp", withExtension: "wav"))
        let player = try AVAudioPlayer(contentsOf: url)
        #expect(player.duration > 0.2)
        #expect(player.duration < 0.8)
    }
}

@MainActor
private func skillStore(
    player: Player,
    clock: TestClock<Duration>,
    prepare: (inout DependencyValues) -> Void = { _ in }
) -> TestStoreOf<SkillChoiceFeature> {
    TestStore(
        initialState: SkillChoiceFeature.State(
            offerID: "offer",
            player: player,
            choices: WeekTuning.current.skillChoices
        )
    ) {
        SkillChoiceFeature()
    } withDependencies: {
        $0.continuousClock = clock
        prepare(&$0)
    }
}

@Suite
@MainActor
struct LineupDialogTests {
    @Test func restAndPlayWaitForAName() async throws {
        let starter = squad(id: "starter", position: .midfielder, starter: true, passing: 70)
        let cover = squad(id: "cover", position: .midfielder, starter: false, passing: 90)
        let other = squad(id: "other", position: .midfielder, starter: false, passing: 50)
        let strong = squad(id: "strong", position: .defender, starter: true, passing: 70, defending: 90)
        let mid = squad(id: "mid", position: .defender, starter: true, passing: 70, defending: 65)
        let weak = squad(id: "weak", position: .defender, starter: true, passing: 70, defending: 40)
        let bench = squad(id: "bench", position: .defender, starter: false, passing: 70, defending: 70)
        #expect(weak.overall < mid.overall)
        #expect(mid.overall < strong.overall)
        let club = Club(
            id: "city",
            name: "City",
            shortName: "CTY",
            listName: "City",
            nickname: "Testers",
            kit: Kit(
                primary: KitColor(red: 0, green: 0, blue: 0),
                secondary: KitColor(red: 1, green: 1, blue: 1)
            ),
            players: [starter, cover, other, strong, mid, weak, bench]
        )
        let store = TestStore(
            initialState: TeamFeature.State(
                club: club,
                won: 2,
                lost: 1,
                drawn: 0,
                points: 6,
                goalDifference: 3,
                place: 4,
                canManage: true
            )
        ) {
            TeamFeature()
        }
        store.exhaustivity = .off

        let rest = try #require(SubstitutionFeature.State.resting(starter, in: club.players))
        #expect(rest.heading == "Replace with")
        #expect(rest.candidates.map(\.id) == ["cover", "other"])

        await store.send(.view(.restStarter(starter.id)))
        #expect(store.state.substitution == rest)
        #expect(store.state.club.starters.contains { $0.id == starter.id })

        await store.send(.substitution(.presented(.view(.cancelTapped))))
        await store.skipReceivedActions()
        #expect(store.state.substitution == nil)
        #expect(store.state.club == club)

        await store.send(.view(.restStarter(starter.id)))
        await store.send(.substitution(.presented(.view(.nameTapped(other.id)))))
        await store.receive { action in
            guard case let .delegate(.replace(outgoing, incoming)) = action else { return false }
            return outgoing == starter.id && incoming == other.id
        }
        #expect(store.state.substitution == nil)
        #expect(store.state.club == club)

        let play = try #require(SubstitutionFeature.State.playing(bench, in: club.players))
        #expect(play.heading == "Replace")
        #expect(play.candidates.map(\.id) == [weak.id, mid.id, strong.id])

        await store.send(.view(.playBench(bench.id)))
        #expect(store.state.substitution == play)
        #expect(store.state.club.starters.contains { $0.id == bench.id } == false)
        await store.send(.substitution(.presented(.view(.nameTapped(strong.id)))))
        await store.receive { action in
            guard case let .delegate(.replace(outgoing, incoming)) = action else { return false }
            return outgoing == strong.id && incoming == bench.id
        }
        #expect(store.state.club == club)
    }
}

private func squad(
    id: String,
    position: Position,
    starter: Bool,
    passing: Int,
    defending: Int = 70
) -> Player {
    Player(
        id: id,
        firstName: "Bo",
        lastName: id,
        position: position,
        condition: 100,
        isStarter: starter,
        ratings: Ratings(
            speed: 70,
            shooting: 70,
            passing: passing,
            dribbling: 70,
            defending: defending,
            goalkeeping: 70
        )
    )
}
