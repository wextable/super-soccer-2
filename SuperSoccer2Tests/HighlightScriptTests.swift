import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct HighlightScriptTests {
    @Test func theSameSeedBuildsTheSameScript() {
        let shot = highlightShot(result: .goal, passer: true)
        let first = HighlightScript.make(shot: shot, matchSeed: 42)
        let second = HighlightScript.make(shot: shot, matchSeed: 42)
        #expect(first == second)
        #expect(first.beats.isEmpty == false)
    }

    @Test func playbackSamplesThePathInsteadOfTheEndpoints() {
        let script = HighlightScript.make(shot: highlightShot(result: .goal, passer: true), matchSeed: 42)
        let start = script.pose(at: 0).ball
        let end = script.pose(at: 1).ball
        #expect(start.distance(to: script.ballStart) < 0.000_001)
        #expect(end.distance(to: script.ballEnd) < 0.000_001)
        var previous = start
        var traveled = 0.0
        var longest = 0.0
        for step in 1...20 {
            let sample = script.pose(at: Double(step) / 20).ball
            let hop = previous.distance(to: sample)
            traveled += hop
            longest = max(longest, hop)
            previous = sample
        }
        let trip = start.distance(to: end)
        #expect(traveled + 0.000_001 >= trip)
        #expect(longest < traveled * 0.5)
        let middle = script.pose(at: 0.45).ball
        #expect(middle.distance(to: start) > 0.01)
        #expect(middle.distance(to: end) > 0.01)
        let shooter = script.actors[0].id
        let shooterStart = script.pose(at: 0).places.first { $0.id == shooter }?.point
        let shooterMiddle = script.pose(at: 0.45).places.first { $0.id == shooter }?.point
        let shooterEnd = script.pose(at: 1).places.first { $0.id == shooter }?.point
        if let shooterStart, let shooterMiddle, let shooterEnd, shooterStart.distance(to: shooterEnd) > 0.05 {
            #expect(shooterMiddle.distance(to: shooterStart) > 0.01)
            #expect(shooterMiddle.distance(to: shooterEnd) > 0.01)
        }
    }

    @Test func openPlayChangesPatternLaneAndPassCount() {
        var templates: Set<HighlightTemplate> = []
        var passCounts: Set<Int> = []
        var starts: [Double] = []
        for id in 0..<40 {
            let shot = highlightShot(id: id, minute: 10, result: .goal, passer: true)
            let script = HighlightScript.make(shot: shot, matchSeed: 5)
            templates.insert(script.template)
            passCounts.insert(script.beats.filter { $0.kind == .pass }.count)
            starts.append(script.ballStart.x)
        }
        #expect(templates.contains(.penalty) == false)
        #expect(templates.count >= 4)
        #expect(passCounts.count >= 2)
        let spread = (starts.max() ?? 0) - (starts.min() ?? 0)
        #expect(spread > 0.25)
    }

    @Test func aPenaltyIsASpotKick() {
        let shot = highlightShot(result: .goal, type: .penalty, passer: false)
        let script = HighlightScript.make(shot: shot, matchSeed: 3)
        #expect(script.template == .penalty)
        #expect(script.beats.contains { $0.kind == .pass } == false)
        #expect(script.beats.last?.kind == .shot)
    }

    @Test func aGoalEndsInTheNetAndASaveEndsWithTheKeeper() {
        for seed in UInt64(1)...8 {
            for id in 0..<3 {
                let goal = HighlightScript.make(
                    shot: highlightShot(id: id, result: .goal, passer: id.isMultiple(of: 2)),
                    matchSeed: seed
                )
                #expect(goal.finish == .net)
                #expect(goal.ballEndsInNet)
                let keeper = keeperEnd(goal)
                #expect(goal.ballEnd.distance(to: keeper) > 0.02)

                let save = HighlightScript.make(
                    shot: highlightShot(id: id, result: .save, passer: true),
                    matchSeed: seed
                )
                #expect(save.finish == .keeper)
                #expect(save.ballEndsInNet == false)
                #expect(save.ballEnd.distance(to: keeperEnd(save)) < 0.000_001)
            }
        }
    }

    @Test func aMissEndsWideOrOver() {
        var finishes: Set<ShotFinish> = []
        for seed in UInt64(1)...16 {
            let script = HighlightScript.make(
                shot: highlightShot(id: Int(seed), result: .miss, passer: false),
                matchSeed: seed
            )
            finishes.insert(script.finish)
            #expect(script.finish == .wide || script.finish == .over)
            #expect(script.ballEndsInNet == false)
            #expect(script.ballEnd.distance(to: keeperEnd(script)) > 0.001)
        }
        #expect(finishes.contains(.wide))
        #expect(finishes.contains(.over))
    }

    @Test func pathsStayOnThePitchAndFollowThePlayers() {
        let results: [ShotResult] = [.goal, .save, .miss]
        for seed in UInt64(1)...6 {
            for (offset, result) in results.enumerated() {
                for home in [true, false] {
                    for minute in [12, 45, 46, 80] {
                        let passer = offset != 1
                        let shot = highlightShot(
                            id: offset + minute,
                            minute: minute,
                            result: result,
                            passer: passer && result != .miss,
                            isHome: home
                        )
                        let script = HighlightScript.make(shot: shot, matchSeed: seed)
                        expectPlausible(script, shot: shot, hasPasser: shot.passer != nil)
                    }
                }
            }
        }
    }

    @Test func teamsSwapEndsAfterHalfTime() {
        #expect(PitchEnd.attacked(byHome: true, minute: 45) == .north)
        #expect(PitchEnd.attacked(byHome: true, minute: 46) == .south)
        #expect(PitchEnd.attacked(byHome: false, minute: 45) == .south)
        #expect(PitchEnd.attacked(byHome: false, minute: 46) == .north)

        let first = highlightShot(minute: 23, result: .goal, passer: true, isHome: true)
        var second = first
        second.minute = 71
        let opening = HighlightScript.make(shot: first, matchSeed: 11)
        let after = HighlightScript.make(shot: second, matchSeed: 11)
        #expect(opening.attackingEnd == .north)
        #expect(after.attackingEnd == .south)
        #expect(opening != after)
        expectMirrored(opening, after)
        #expect(opening.ballEnd.inAttackingView(of: opening.attackingEnd).y == 0)
        #expect(after.ballEnd.inAttackingView(of: after.attackingEnd).y == 0)

        var away = first
        away.isHome = false
        var awayLater = away
        awayLater.minute = 80
        let awayFirst = HighlightScript.make(shot: away, matchSeed: 11)
        let awaySecond = HighlightScript.make(shot: awayLater, matchSeed: 11)
        #expect(awayFirst.attackingEnd == .south)
        #expect(awaySecond.attackingEnd == .north)
        expectMirrored(awaySecond, awayFirst)
    }
}

private func expectMirrored(_ north: HighlightScript, _ south: HighlightScript) {
    #expect(north.template == south.template)
    #expect(north.finish == south.finish)
    #expect(north.actors == south.actors)
    #expect(north.beats.count == south.beats.count)
    for (left, right) in zip(north.beats, south.beats) {
        #expect(left.kind == right.kind)
        #expect(left.weight == right.weight)
        expectFlipped(left.ballStart, right.ballStart)
        expectFlipped(left.ballEnd, right.ballEnd)
        #expect(left.moves.count == right.moves.count)
        for (leftMove, rightMove) in zip(left.moves, right.moves) {
            #expect(leftMove.actorID == rightMove.actorID)
            expectFlipped(leftMove.start, rightMove.start)
            expectFlipped(leftMove.end, rightMove.end)
        }
    }
}

private func expectFlipped(_ north: PitchPoint, _ south: PitchPoint) {
    #expect(south.x == north.x)
    #expect(south.y == 1 - north.y)
}

private func expectPlausible(_ script: HighlightScript, shot: Shot, hasPasser: Bool) {
    #expect((3...6).contains(script.actors.count))
    #expect(script.actors.filter { $0.role == .shooter }.count == 1)
    #expect(script.actors.filter { $0.role == .keeper }.count == 1)
    #expect(script.actors.contains { $0.role == .defender })
    #expect(script.attackingEnd == PitchEnd.attacked(byHome: shot.isHome, minute: shot.minute))
    #expect(script.beats.last?.kind == .shot)
    if hasPasser {
        #expect(script.actors.contains { $0.role == .passer })
        let passes = script.beats.filter { $0.kind == .pass }
        #expect(passes.isEmpty == false)
        let lastPass = passes[passes.count - 1]
        let passer = script.actors.first { $0.role == .passer }!
        let shooter = script.actors.first { $0.role == .shooter }!
        let passerStart = lastPass.moves.first { $0.actorID == passer.id }!
        let shooterEnd = lastPass.moves.first { $0.actorID == shooter.id }!
        #expect(passerStart.start.distance(to: lastPass.ballStart) < 0.000_001)
        #expect(shooterEnd.end.distance(to: lastPass.ballEnd) < 0.000_001)
    }

    var previousEnd: PitchPoint?
    for beat in script.beats {
        expectOnPitch(beat.ballStart)
        expectOnPitch(beat.ballEnd)
        let ballLeavesAPlayer = beat.moves.contains { $0.start.distance(to: beat.ballStart) < 0.000_001 }
        #expect(ballLeavesAPlayer)
        if beat.kind == .pass || beat.kind == .carry {
            let met = beat.moves.contains { move in
                guard let actor = script.actors.first(where: { $0.id == move.actorID }) else { return false }
                return actor.attacks && actor.role != .keeper && move.end.distance(to: beat.ballEnd) < 0.000_001
            }
            #expect(met)
        }
        if let previousEnd {
            #expect(beat.ballStart.distance(to: previousEnd) < 0.000_001)
        }
        previousEnd = beat.ballEnd
        for move in beat.moves {
            expectOnPitch(move.start)
            expectOnPitch(move.end)
            guard let actor = script.actors.first(where: { $0.id == move.actorID }) else {
                Issue.record("Missing actor")
                continue
            }
            if actor.role == .keeper {
                #expect(move.start.isInSixYard(of: script.attackingEnd))
                #expect(move.end.isInSixYard(of: script.attackingEnd))
            }
            if actor.role == .defender {
                #expect(move.start.distance(to: beat.ballStart) > 0.02)
                #expect(move.end.distance(to: beat.ballEnd) > 0.02)
            }
        }
    }

    let shotBeat = script.beats[script.beats.count - 1]
    let shooter = script.actors.first { $0.role == .shooter }!
    let shooterMove = shotBeat.moves.first { $0.actorID == shooter.id }!
    #expect(shooterMove.start.distance(to: shotBeat.ballStart) < 0.000_001)
    switch shot.result {
    case .goal:
        #expect(script.finish == .net)
        #expect(script.ballEndsInNet)
    case .save:
        #expect(script.finish == .keeper)
        #expect(script.ballEnd.distance(to: keeperEnd(script)) < 0.000_001)
    case .miss:
        #expect(script.finish == .wide || script.finish == .over)
        #expect(script.ballEndsInNet == false)
    }
}

private func expectOnPitch(_ point: PitchPoint) {
    #expect(point.x >= 0 && point.x <= 1)
    #expect(point.y >= 0 && point.y <= 1)
}

private func keeperEnd(_ script: HighlightScript) -> PitchPoint {
    let keeper = script.actors.first { $0.role == .keeper }!
    let move = script.beats[script.beats.count - 1].moves.first { $0.actorID == keeper.id }!
    return move.end
}

private func highlightShot(
    id: Int = 0,
    minute: Int = 12,
    result: ShotResult,
    type: ShotType = .regular,
    passer: Bool = false,
    isHome: Bool = true
) -> Shot {
    let ratings = Ratings(speed: 70, shooting: 80, passing: 70, dribbling: 70, defending: 40, goalkeeping: 10)
    let shooter = Player(
        id: "shooter",
        firstName: "Bo",
        lastName: "Scaramucci",
        position: .forward,
        condition: 100,
        ratings: ratings
    )
    let keeperRatings = Ratings(speed: 40, shooting: 20, passing: 40, dribbling: 20, defending: 60, goalkeeping: 80)
    let keeper = Player(
        id: "keeper",
        firstName: "Hank",
        lastName: "Keeper",
        position: .keeper,
        condition: 100,
        ratings: keeperRatings
    )
    let assistant: Player? = passer
        ? Player(
            id: "passer",
            firstName: "Chode",
            lastName: "Magnusson",
            position: .midfielder,
            condition: 100,
            ratings: ratings
        )
        : nil
    return Shot(
        id: id,
        type: type,
        result: result,
        shooter: shooter,
        passer: assistant,
        keeper: keeper,
        minute: minute,
        isHome: isHome
    )
}
