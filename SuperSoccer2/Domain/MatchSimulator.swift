import Foundation

/// Seeded port of the previous match. Same clubs and seed, same score, shots, and line.
enum MatchSimulator {
    static func simulate(home: Club, away: Club, seed: UInt64) -> MatchResult {
        var rng = SeededGenerator(seed: seed)
        let homeAttack = home.attack
        let awayAttack = away.attack
        let homeDefense = home.defense
        let awayDefense = away.defense

        let homeMean = Double(homeAttack - awayDefense) / 7.5 + 1 + 0.25
        let awayMean = Double(awayAttack - homeDefense) / 7.5 + 1
        let homeGoals = rolledGoals(mean: homeMean, using: &rng)
        let awayGoals = rolledGoals(mean: awayMean, using: &rng)

        var shots: [Shot] = []
        shots += scoringShots(
            count: homeGoals,
            attacking: home,
            defending: away,
            isHome: true,
            using: &rng
        )
        shots += scoringShots(
            count: awayGoals,
            attacking: away,
            defending: home,
            isHome: false,
            using: &rng
        )
        shots += nonGoalShots(
            attack: homeAttack,
            attacking: home,
            defending: away,
            isHome: true,
            using: &rng
        )
        shots += nonGoalShots(
            attack: awayAttack,
            attacking: away,
            defending: home,
            isHome: false,
            using: &rng
        )

        let ordered = shots.sorted { $0.minute < $1.minute }.enumerated().map { index, shot in
            var copy = shot
            copy.id = index
            return copy
        }
        let highlight = highlightShot(in: ordered, homeScore: homeGoals, awayScore: awayGoals)
        let attacking = highlight.isHome ? home : away
        let defending = highlight.isHome ? away : home
        return MatchResult(
            homeScore: homeGoals,
            awayScore: awayGoals,
            shots: ordered,
            highlight: highlight,
            commentary: Commentary.line(
                shot: highlight,
                attackingClub: attacking.name,
                defendingClub: defending.name
            ),
            seed: seed
        )
    }

    /// First goal in minute order, or the first non-goal when the match is 0–0.
    static func highlightShot(in shots: [Shot], homeScore: Int, awayScore: Int) -> Shot {
        if homeScore == 0, awayScore == 0 {
            return shots[0]
        }
        return shots.first { $0.result == .goal } ?? shots[0]
    }

    static func pickScorer(
        from starters: [Player],
        using rng: inout some RandomNumberGenerator
    ) -> Player {
        var entries: [(Player, Double)] = []
        for player in starters {
            let multiplier: Double
            switch player.position {
            case .keeper:
                continue
            case .defender:
                multiplier = 1.5
            case .midfielder:
                multiplier = 2
            case .forward:
                multiplier = 2.5
            }
            let weight = Double(player.scoring - 50) * multiplier
            // A non-positive weight is zero. The old wheel kept negatives and could blow up.
            guard weight > 0 else { continue }
            entries.append((player, weight))
        }
        if let picked = roulette(entries, using: &rng) {
            return picked
        }
        return starters.first { $0.position != .keeper } ?? starters[0]
    }

    static func pickPasser(
        from starters: [Player],
        shooter: Player,
        using rng: inout some RandomNumberGenerator
    ) -> Player? {
        guard Int.random(in: 0..<100, using: &rng) < 60 else { return nil }
        var entries: [(Player, Int)] = []
        for player in starters {
            guard player.id != shooter.id else { continue }
            let multiplier: Int
            switch player.position {
            case .keeper:
                continue
            case .defender:
                multiplier = 1
            case .midfielder:
                multiplier = 2
            case .forward:
                multiplier = 3
            }
            let weight = player.assist * multiplier
            guard weight > 0 else { continue }
            entries.append((player, weight))
        }
        return roulette(entries, using: &rng)
    }

    private static func rolledGoals(
        mean: Double,
        using rng: inout SeededGenerator
    ) -> Int {
        let draw = rng.nextGoalNoise()
        return max(0, Int((mean + draw).rounded()))
    }

    private static func scoringShots(
        count: Int,
        attacking: Club,
        defending: Club,
        isHome: Bool,
        using rng: inout SeededGenerator
    ) -> [Shot] {
        let minutes = (0..<count).map { _ in Int.random(in: 1...90, using: &rng) }.sorted()
        return minutes.map { minute in
            makeShot(
                attacking: attacking,
                defending: defending,
                minute: minute,
                isHome: isHome,
                result: .goal,
                penaltyChance: 15,
                using: &rng
            )
        }
    }

    private static func nonGoalShots(
        attack: Int,
        attacking: Club,
        defending: Club,
        isHome: Bool,
        using rng: inout SeededGenerator
    ) -> [Shot] {
        let count = nonGoalCount(attack: attack, using: &rng)
        let minutes = (0..<count).map { _ in Int.random(in: 1...90, using: &rng) }.sorted()
        return minutes.map { minute in
            let shot = makeShot(
                attacking: attacking,
                defending: defending,
                minute: minute,
                isHome: isHome,
                result: .miss,
                penaltyChance: 5,
                using: &rng
            )
            var finished = shot
            let goalkeeping = defending.keeper.ratings.goalkeeping
            if Int.random(in: 0..<100, using: &rng) < (goalkeeping - 50) {
                finished.result = .save
            }
            return finished
        }
    }

    private static func nonGoalCount(
        attack: Int,
        using rng: inout SeededGenerator
    ) -> Int {
        switch attack {
        case 85...:
            Int.random(in: 5...12, using: &rng)
        case 80..<85:
            Int.random(in: 4...10, using: &rng)
        case 75..<80:
            Int.random(in: 3...8, using: &rng)
        case 70..<75:
            Int.random(in: 2...6, using: &rng)
        default:
            Int.random(in: 1...4, using: &rng)
        }
    }

    private static func makeShot(
        attacking: Club,
        defending: Club,
        minute: Int,
        isHome: Bool,
        result: ShotResult,
        penaltyChance: Int,
        using rng: inout SeededGenerator
    ) -> Shot {
        let shooter = pickScorer(from: attacking.starters, using: &rng)
        let passer = pickPasser(from: attacking.starters, shooter: shooter, using: &rng)
        var type = ShotType.regular
        if passer == nil, Int.random(in: 0..<100, using: &rng) < penaltyChance {
            type = .penalty
        }
        return Shot(
            id: 0,
            type: type,
            result: result,
            shooter: shooter,
            passer: passer,
            keeper: defending.keeper,
            minute: minute,
            isHome: isHome
        )
    }

    private static func roulette(
        _ entries: [(Player, Double)],
        using rng: inout some RandomNumberGenerator
    ) -> Player? {
        let total = entries.reduce(0.0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var roll = Double(Int.random(in: 0...Int(total), using: &rng))
        for (player, weight) in entries {
            if roll <= weight {
                return player
            }
            roll -= weight
        }
        return entries.last?.0
    }

    private static func roulette(
        _ entries: [(Player, Int)],
        using rng: inout some RandomNumberGenerator
    ) -> Player? {
        let total = entries.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var roll = Int.random(in: 0...total, using: &rng)
        for (player, weight) in entries {
            if roll <= weight {
                return player
            }
            roll -= weight
        }
        return entries.last?.0
    }
}
