import ComposableArchitecture
import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct RatingTrackTests {
    @Test func ninetyDegradedToEightyFillsEightUnitsAndMarksTheNinth() {
        let track = RatingTrack.fitness(full: 90, current: 80)
        #expect(track.filledPoints / RatingTrack.pointsPerUnit == 8)
        #expect(track.markedPoints / RatingTrack.pointsPerUnit == 1)
        #expect(track.emptyPoints / RatingTrack.pointsPerUnit == 1)
        #expect(track.filledPoints + track.markedPoints + track.emptyPoints == RatingTrack.trackPoints)
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
        let track = RatingTrack.fitness(full: 90, current: current)
        #expect(track.filledPoints == current)
        #expect(track.markedPoints == 90 - current)
        #expect(track.emptyPoints == RatingTrack.trackPoints - 90)

        player.condition = WeekTuning.current.greenMinimum
        #expect(player.playingRating(.speed) == 90)
        let full = RatingTrack.fitness(full: 90, current: player.playingRating(.speed))
        #expect(full.markedPoints == 0)
        #expect(full.emptyPoints == 10)
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
        #expect(RatingTrack.growth(capped).emptyPoints == 1)

        let full = SkillProjection.make(current: 99, boost: shooting)
        #expect(full.available == false)
        #expect(full.reading == "99")
        #expect(full.next == 99)
        #expect(RatingTrack.growth(full).markedPoints == 0)
    }

    @Test func growthAndConditionStayInsideOneTrack() {
        let tired = RatingTrack.fitness(full: 90, current: 80)
        let growing = RatingTrack.growth(SkillProjection.make(current: 80, boost: 5))
        #expect(tired.filledPoints + tired.markedPoints + tired.emptyPoints == RatingTrack.trackPoints)
        #expect(growing.filledPoints + growing.markedPoints + growing.emptyPoints == RatingTrack.trackPoints)
        #expect(tired.filledPoints == 80)
        #expect(tired.markedPoints == 10)
        #expect(growing.filledPoints == 80)
        #expect(growing.markedPoints == 5)
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
        let store = TestStore(
            initialState: SkillChoiceFeature.State(
                offerID: "offer",
                player: player,
                choices: WeekTuning.current.skillChoices,
                step: 1,
                stepCount: 1,
                contextLine: "Before the next week"
            )
        ) {
            SkillChoiceFeature()
        }

        await store.send(.view(.statTapped(.shooting)))
        let defending = try #require(WeekTuning.current.skillChoices.first { $0.stat == .defending })
        let projection = SkillProjection.make(current: 97, boost: defending.points)
        #expect(projection.reading == "97→99")
        await store.send(.view(.statTapped(.defending)))
        await store.receive(\.delegate.chose, .defending)
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
        let weak = squad(id: "weak", position: .defender, starter: true, passing: 70, defending: 40)
        let bench = squad(id: "bench", position: .defender, starter: false, passing: 70, defending: 70)
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
            players: [starter, cover, other, strong, weak, bench]
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
        #expect(play.heading == "Replace with")
        #expect(play.candidates.map(\.id) == [weak.id, strong.id])

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
