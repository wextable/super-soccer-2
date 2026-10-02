import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct MatchCommentaryTests {
    @Test func theMatchSeedPicksOneCommentator() {
        #expect(Commentator.forMatch(seed: 0) == .pemberton)
        #expect(Commentator.forMatch(seed: 1) == .cobb)
        #expect(Commentator.forMatch(seed: 2) == .mulch)
        #expect(Commentator.forMatch(seed: 3) == Commentator.forMatch(seed: 0))
        #expect(Commentator.forMatch(seed: 0).name == "Alistair Pemberton")
        #expect(Commentator.forMatch(seed: 1).name == "Randy Cobb")
        #expect(Commentator.forMatch(seed: 2).name == "Terry Mulch")

        let shot = commentaryShot(result: .goal, passer: true)
        let first = MatchCommentary.make(shot: shot, matchSeed: 42)
        let second = MatchCommentary.make(shot: shot, matchSeed: 42)
        #expect(first == second)
        #expect(first.commentator == Commentator.forMatch(seed: 42))

        var changed = commentaryShot(id: 9, result: .miss, passer: true)
        changed.minute = 70
        let other = MatchCommentary.make(shot: changed, matchSeed: 42)
        #expect(other.commentator == first.commentator)
        #expect(other.result != first.result)
    }

    @Test func aGoalNamesTheScorer() {
        for seed in UInt64(0)..<12 {
            let shot = commentaryShot(id: Int(seed), result: .goal, passer: seed.isMultiple(of: 2))
            let line = MatchCommentary.make(shot: shot, matchSeed: seed)
            #expect(line.result.contains("Scaramucci"))
            #expect(sentenceCount(line.result) == 1)
        }
    }

    @Test func eachPersonaSoundsLikeItself() {
        let results: [ShotResult] = [.goal, .save, .miss]
        for seed in UInt64(0)..<36 {
            for (offset, result) in results.enumerated() {
                let shot = commentaryShot(
                    id: offset,
                    minute: 10 + offset,
                    result: result,
                    passer: offset == 0,
                    isHome: offset.isMultiple(of: 2)
                )
                let line = MatchCommentary.make(shot: shot, matchSeed: seed)
                expectVoice(line, shot: shot)
            }
        }
    }

    @Test func aShortChanceDoesNotGrowAParagraph() {
        for seed in UInt64(0)..<24 {
            let penalty = commentaryShot(id: Int(seed), result: .goal, type: .penalty, passer: false)
            let solo = commentaryShot(id: Int(seed), minute: 20, result: .miss, passer: false)
            for shot in [penalty, solo] {
                let script = HighlightScript.make(shot: shot, matchSeed: seed)
                #expect(script.beats.count < 3)
                let line = MatchCommentary.make(shot: shot, matchSeed: seed)
                #expect(line.aside.isEmpty)
                #expect(line.lead.contains("oceans") == false)
                #expect(line.lead.contains("room") == false)
                #expect(line.lead.contains(" to ") == false)
                #expect(sentenceCount(line.caption) <= 2)
                #expect(words(line.caption) <= 16)
            }
        }
    }

    @Test func aLongChanceKeepsToOneAside() {
        var ornate = 0
        var silly = 0
        var longCount = 0
        for seed in UInt64(0)..<60 {
            let shot = commentaryShot(id: Int(seed % 7), result: .goal, passer: true)
            let script = HighlightScript.make(shot: shot, matchSeed: seed)
            guard script.beats.count >= 3 else { continue }
            longCount += 1
            let line = MatchCommentary.make(shot: shot, matchSeed: seed)
            #expect(sentenceCount(line.caption) <= 3)
            #expect(words(line.caption) <= 32)
            #expect(line.caption.contains("Defender") == false)
            #expect(line.caption.contains("Teammate") == false)
            if line.aside.isEmpty {
                continue
            }
            #expect(sentenceCount(line.aside) == 1)
            #expect(line.caption.components(separatedBy: line.aside).count == 2)
            switch line.commentator {
            case .pemberton:
                #expect(line.aside.contains("mystification") || line.aside.contains("bewildered"))
                #expect(line.caption.hasSuffix(line.result))
                ornate += 1
            case .mulch:
                #expect(line.aside.contains("fridge") || line.aside.contains("thought") || line.aside.contains("swan"))
                #expect(line.caption.hasPrefix(line.lead.isEmpty ? line.result : line.lead) || line.caption.contains(line.result))
                let resultAt = line.caption.range(of: line.result)
                let asideAt = line.caption.range(of: line.aside)
                #expect((resultAt?.lowerBound ?? line.caption.endIndex) < (asideAt?.lowerBound ?? line.caption.startIndex))
                silly += 1
            case .cobb:
                Issue.record("Cobb stays short")
            }
        }
        #expect(longCount > 0)
        #expect(ornate > 0)
        #expect(silly > 0)
    }

    @Test func aSharedSurnameIsSpelledOut() {
        let shot = commentaryShot(
            result: .goal,
            passer: true,
            shooter: ("Bo", "Hayes"),
            passerName: ("Ada", "Hayes"),
            keeper: ("Hank", "Keeper")
        )
        for seed in UInt64(0)..<15 {
            let line = MatchCommentary.make(shot: shot, matchSeed: seed)
            #expect(line.result.contains("Bo Hayes"))
            expectQualified(line.caption, surname: "Hayes", firsts: ["Bo", "Ada"])
            #expect(line.caption.contains("Hank") == false)
            if line.caption.contains("Ada") {
                #expect(line.caption.contains("Ada Hayes"))
            }
            if line.caption.contains("Keeper") {
                #expect(line.caption.contains("Hank Keeper") == false)
            }
        }
    }

    @Test func aUniqueSurnameStaysASurname() {
        let shot = commentaryShot(result: .save, passer: true)
        for seed in UInt64(0)..<12 {
            let line = MatchCommentary.make(shot: shot, matchSeed: seed)
            #expect(line.caption.contains("Bo ") == false)
            #expect(line.caption.contains("Chode") == false)
            #expect(line.caption.contains("Hank") == false)
            #expect(line.result.contains("Keeper"))
        }
    }
}

private func expectVoice(_ line: MatchCommentary, shot: Shot) {
    #expect(sentenceCount(line.result) == 1)
    let shooter = shot.shooter.lastName
    let keeper = shot.keeper.lastName
    switch line.commentator {
    case .pemberton:
        #expect(line.caption.contains("!") == false)
        #expect(line.caption.contains("skies") == false)
        #expect(line.caption.contains("fridge") == false)
        #expect(line.caption.contains("buries") == false)
        if shot.result == .goal {
            #expect(line.result.contains("rather beautifully"))
            #expect(line.result.contains(shooter))
        }
        if shot.result == .save {
            #expect(line.result.contains("which will do"))
            #expect(line.result.contains(keeper))
        }
        if shot.result == .miss {
            #expect(line.result.contains("puts it") || line.result.contains("misses from the spot"))
        }
    case .cobb:
        #expect(line.aside.isEmpty)
        #expect(line.caption.contains("rather") == false)
        #expect(line.caption.contains("mystification") == false)
        #expect(line.caption.contains("fridge") == false)
        #expect(words(line.caption) <= 12)
        if shot.result == .goal {
            #expect(line.result.contains(shooter))
            #expect(line.result.contains("buries"))
            #expect(line.result.contains("!"))
        }
        if shot.result == .save {
            #expect(line.result.contains("stops"))
            #expect(line.result.contains(keeper))
        }
        if shot.result == .miss {
            #expect(line.result.contains("skies") || line.result.contains("shanks"))
            #expect(line.caption.contains("!"))
        }
    case .mulch:
        #expect(line.caption.contains("rather beautifully") == false)
        #expect(line.caption.contains("buries") == false)
        #expect(line.caption.contains("skies") == false)
        switch shot.result {
        case .goal:
            #expect(line.result == (shot.type == .penalty ? "\(shooter) scores the penalty." : "\(shooter) scores."))
        case .save:
            #expect(line.result == (shot.type == .penalty ? "\(keeper) saves the penalty." : "\(keeper) saves."))
        case .miss:
            #expect(line.result == (shot.type == .penalty ? "\(shooter) misses the penalty." : "\(shooter) misses."))
        }
        if !line.aside.isEmpty {
            let resultAt = line.caption.range(of: line.result)
            let asideAt = line.caption.range(of: line.aside)
            #expect((resultAt?.lowerBound ?? line.caption.endIndex) < (asideAt?.lowerBound ?? line.caption.startIndex))
        }
    }
}

private func expectQualified(_ text: String, surname: String, firsts: [String]) {
    var rest = text[...]
    var saw = false
    while let range = rest.range(of: surname) {
        saw = true
        let prefix = rest[..<range.lowerBound]
        let qualified = firsts.contains { prefix.hasSuffix("\($0) ") }
        #expect(qualified)
        rest = rest[range.upperBound...]
    }
    #expect(saw)
}

private func sentenceCount(_ text: String) -> Int {
    text.filter { ".!?".contains($0) }.count
}

private func words(_ text: String) -> Int {
    text.split { $0.isWhitespace }.count
}

private func commentaryShot(
    id: Int = 0,
    minute: Int = 12,
    result: ShotResult,
    type: ShotType = .regular,
    passer: Bool = false,
    shooter: (String, String) = ("Bo", "Scaramucci"),
    passerName: (String, String) = ("Chode", "Magnusson"),
    keeper: (String, String) = ("Hank", "Keeper"),
    isHome: Bool = true
) -> Shot {
    let ratings = Ratings(speed: 70, shooting: 80, passing: 70, dribbling: 70, defending: 40, goalkeeping: 10)
    let finisher = Player(
        id: "shooter",
        firstName: shooter.0,
        lastName: shooter.1,
        position: .forward,
        condition: 100,
        ratings: ratings
    )
    let assistant: Player? = passer
        ? Player(
            id: "passer",
            firstName: passerName.0,
            lastName: passerName.1,
            position: .midfielder,
            condition: 100,
            ratings: ratings
        )
        : nil
    let goalkeeper = Player(
        id: "keeper",
        firstName: keeper.0,
        lastName: keeper.1,
        position: .keeper,
        condition: 100,
        ratings: Ratings(speed: 40, shooting: 20, passing: 40, dribbling: 20, defending: 60, goalkeeping: 80)
    )
    return Shot(
        id: id,
        type: type,
        result: result,
        shooter: finisher,
        passer: assistant,
        keeper: goalkeeper,
        minute: minute,
        isHome: isHome
    )
}
