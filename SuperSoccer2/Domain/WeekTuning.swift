import Foundation

/// How fit a player is for the next match.
/// Green is full ratings. Yellow is a mild drop. Orange is close to red. Red is the high risk.
enum FitnessBand: Equatable, Sendable {
    case green
    case yellow
    case orange
    case red

    var label: String {
        switch self {
        case .green: "Green"
        case .yellow: "Yellow"
        case .orange: "Orange"
        case .red: "Red"
        }
    }

    /// A higher rank is fitter. Other clubs only bring in someone from a higher rank.
    var rank: Int {
        switch self {
        case .green: 3
        case .yellow: 2
        case .orange: 1
        case .red: 0
        }
    }

    func isFitter(than other: FitnessBand) -> Bool {
        rank > other.rank
    }
}

/// One of the six ratings. A skill pick adds points to exactly one of these.
enum PlayerStat: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case speed
    case shooting
    case passing
    case dribbling
    case defending
    case goalkeeping

    var id: String { rawValue }

    var label: String {
        switch self {
        case .speed: "Speed"
        case .shooting: "Shooting"
        case .passing: "Passing"
        case .dribbling: "Dribbling"
        case .defending: "Defending"
        case .goalkeeping: "Goalkeeping"
        }
    }

    /// What another club spends a skill on when nobody is choosing.
    static func preferred(for position: Position) -> PlayerStat {
        switch position {
        case .keeper: .goalkeeping
        case .defender: .defending
        case .midfielder: .passing
        case .forward: .shooting
        }
    }
}

/// A stat the player can spend a skill on, with the points that skill adds.
struct SkillChoice: Codable, Equatable, Sendable, Identifiable {
    var stat: PlayerStat
    var points: Int

    var id: PlayerStat { stat }
}

/// One player earned one skill. The stat is still unspent until someone picks it.
struct SkillOffer: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var playerID: String
    var clubID: String
}

/// Age, ceilings, and pace rolled for one player. The kickoff ratings are not in here.
struct Development: Equatable, Sendable {
    var age: Int
    var potential: Potential
    var growth: Growth
}

/// Weights for the week between matches. A later settings screen can bind each field.
/// The goal-mean constants stay on `MatchTuning`.
struct WeekTuning: Equatable, Sendable {
    /// The most condition a starter loses after the match. Each player drains somewhere from one point up to this, so a side does not change band in the same week.
    var fitnessLossPerStart: Int
    /// Fitness a healthy unused player gains. One week of this clears most of a run into the red.
    var benchRecovery: Int
    /// Condition at or above this is green.
    var greenMinimum: Int
    /// Condition at or above this, and below green, is yellow. A mild drop.
    var yellowMinimum: Int
    /// Condition at or above this, and below yellow, is orange. Close to red. Below this is red.
    var orangeMinimum: Int
    /// Percent chance a green starter is hurt. Negligible.
    var injuryChanceGreen: Int
    /// Percent chance a yellow starter is hurt. Milder than orange.
    var injuryChanceYellow: Int
    /// Percent chance an orange starter is hurt. Higher than yellow. Red stays higher.
    var injuryChanceOrange: Int
    /// Percent chance a red starter is hurt. High.
    var injuryChanceRed: Int
    /// Multiplier on the ratings the match already uses. Green leaves them alone.
    var ratingScaleGreen: Double
    var ratingScaleYellow: Double
    var ratingScaleOrange: Double
    var ratingScaleRed: Double
    var xpForStart: Int
    var xpForGoal: Int
    var xpForAssist: Int
    var xpForSave: Int
    var xpForKeeperCleanSheet: Int
    var xpForDefenderCleanSheet: Int
    /// Experience for the first level. Later levels cost this plus `extraXpPerSkill` times levels already earned.
    /// The draft places each player somewhere below this, so the same gain does not level the whole side in one week.
    var xpForFirstSkill: Int
    var extraXpPerSkill: Int
    var skillPointsSpeed: Int
    var skillPointsShooting: Int
    var skillPointsPassing: Int
    var skillPointsDribbling: Int
    var skillPointsDefending: Int
    var skillPointsGoalkeeping: Int
    /// Fitness when an injury reaches zero weeks.
    var conditionOnRecovery: Int
    var injuryWeeksMin: Int
    var injuryWeeksMax: Int
    /// Youngest age the draft rolls, in years.
    var youngestAge: Int
    /// First year of the prime band. Ages below this are young and keep more room.
    var primeAge: Int
    /// First year of the older band. These players sit close to the ceiling. Decline stays off.
    var olderAge: Int
    /// Oldest age the draft rolls, in years.
    var oldestAge: Int
    var youngAgeWeight: Int
    var primeAgeWeight: Int
    var olderAgeWeight: Int
    /// Room above the current rating, inclusive. The span is the player-to-player noise.
    var youngRoomMin: Int
    var youngRoomMax: Int
    var primeRoomMin: Int
    var primeRoomMax: Int
    var olderRoomMin: Int
    var olderRoomMax: Int
    /// Experience multiplier for each stored pace. Applied to the week's total, then rounded.
    var slowGrowth: Double
    var medGrowth: Double
    var fastGrowth: Double
    /// A ceiling at or above this is high. Fast growth is more common there, and it is a separate roll.
    var highCeiling: Int
    var modestSlowWeight: Int
    var modestMedWeight: Int
    var modestFastWeight: Int
    var highSlowWeight: Int
    var highMedWeight: Int
    var highFastWeight: Int
    /// Mixed into the league seed so age, potential, and growth do not move the rating generator.
    var traitSalt: UInt64

    /// Years written onto a player saved before age existed.
    static let missingAge = 26

    /// A month of starts stays green. The next starts are yellow, a mild drop.
    /// Orange is the longer run after that, close to red. Red stays the high risk.
    /// One bench week puts the first red week back in the green.
    static let current = WeekTuning(
        fitnessLossPerStart: 2,
        benchRecovery: 28,
        greenMinimum: 84,
        yellowMinimum: 78,
        orangeMinimum: 64,
        injuryChanceGreen: 1,
        injuryChanceYellow: 6,
        injuryChanceOrange: 22,
        injuryChanceRed: 40,
        ratingScaleGreen: 1,
        ratingScaleYellow: 0.96,
        ratingScaleOrange: 0.90,
        ratingScaleRed: 0.88,
        xpForStart: 10,
        xpForGoal: 5,
        xpForAssist: 2,
        xpForSave: 2,
        xpForKeeperCleanSheet: 2,
        xpForDefenderCleanSheet: 3,
        xpForFirstSkill: 100,
        extraXpPerSkill: 10,
        skillPointsSpeed: 5,
        skillPointsShooting: 5,
        skillPointsPassing: 5,
        skillPointsDribbling: 5,
        skillPointsDefending: 3,
        skillPointsGoalkeeping: 3,
        conditionOnRecovery: 84,
        injuryWeeksMin: 1,
        injuryWeeksMax: 3,
        youngestAge: 17,
        primeAge: 22,
        olderAge: 29,
        oldestAge: 36,
        youngAgeWeight: 25,
        primeAgeWeight: 50,
        olderAgeWeight: 25,
        youngRoomMin: 6,
        youngRoomMax: 30,
        primeRoomMin: 0,
        primeRoomMax: 16,
        olderRoomMin: 0,
        olderRoomMax: 5,
        slowGrowth: 0.8,
        medGrowth: 1.0,
        fastGrowth: 1.3,
        highCeiling: 90,
        modestSlowWeight: 40,
        modestMedWeight: 45,
        modestFastWeight: 15,
        highSlowWeight: 15,
        highMedWeight: 40,
        highFastWeight: 45,
        traitSalt: 0xA6E1_5A7E
    )

    func band(for condition: Int) -> FitnessBand {
        if condition >= greenMinimum { return .green }
        if condition >= yellowMinimum { return .yellow }
        if condition >= orangeMinimum { return .orange }
        return .red
    }

    func ratingScale(for band: FitnessBand) -> Double {
        switch band {
        case .green: ratingScaleGreen
        case .yellow: ratingScaleYellow
        case .orange: ratingScaleOrange
        case .red: ratingScaleRed
        }
    }

    func injuryChance(for band: FitnessBand) -> Int {
        switch band {
        case .green: injuryChanceGreen
        case .yellow: injuryChanceYellow
        case .orange: injuryChanceOrange
        case .red: injuryChanceRed
        }
    }

    func points(for stat: PlayerStat) -> Int {
        switch stat {
        case .speed: skillPointsSpeed
        case .shooting: skillPointsShooting
        case .passing: skillPointsPassing
        case .dribbling: skillPointsDribbling
        case .defending: skillPointsDefending
        case .goalkeeping: skillPointsGoalkeeping
        }
    }

    /// Experience still to earn before the next level. Level 0 costs `xpForFirstSkill`. Each level after that costs ten more at the shipped tuning.
    func requiredXP(level: Int) -> Int {
        xpForFirstSkill + extraXpPerSkill * level
    }

    func growthRate(_ growth: Growth) -> Double {
        switch growth {
        case .slow: slowGrowth
        case .med: medGrowth
        case .fast: fastGrowth
        }
    }

    /// The week's experience after this player's pace. The global amounts stay put. The result is an integer.
    func earnedXP(_ raw: Int, growth: Growth) -> Int {
        let gain = max(0, raw)
        return Int((Double(gain) * growthRate(growth)).rounded())
    }

    /// How many points of ceiling sit above a rating at this age. Inclusive.
    func roomRange(for age: Int) -> ClosedRange<Int> {
        if age < primeAge {
            return youngRoomMin...youngRoomMax
        }
        if age < olderAge {
            return primeRoomMin...primeRoomMax
        }
        return olderRoomMin...olderRoomMax
    }

    /// Age, then a ceiling for each attribute, then a pace. The pace is not the ceiling roll.
    func rollDevelopment(ratings: Ratings, using generator: inout SeededGenerator) -> Development {
        let age = rollAge(using: &generator)
        let potential = rollPotential(ratings: ratings, age: age, using: &generator)
        let growth = rollGrowth(potential: potential, using: &generator)
        return Development(age: age, potential: potential, growth: growth)
    }

    private func rollAge(using generator: inout SeededGenerator) -> Int {
        let young = youngestAge...max(youngestAge, primeAge - 1)
        let prime = primeAge...max(primeAge, olderAge - 1)
        let older = olderAge...max(olderAge, oldestAge)
        let band = pick(
            [(young, youngAgeWeight), (prime, primeAgeWeight), (older, olderAgeWeight)],
            using: &generator
        )
        return Int.random(in: band, using: &generator)
    }

    private func rollPotential(ratings: Ratings, age: Int, using generator: inout SeededGenerator) -> Potential {
        let span = roomRange(for: age)
        func ceiling(_ current: Int) -> Int {
            let rating = min(99, max(0, current))
            let room = Int.random(in: span, using: &generator)
            return min(99, max(rating, rating + room))
        }
        return Potential(
            speed: ceiling(ratings.speed),
            shooting: ceiling(ratings.shooting),
            passing: ceiling(ratings.passing),
            dribbling: ceiling(ratings.dribbling),
            defending: ceiling(ratings.defending),
            goalkeeping: ceiling(ratings.goalkeeping)
        )
    }

    private func rollGrowth(potential: Potential, using generator: inout SeededGenerator) -> Growth {
        let high = potential.highest >= highCeiling
        let options: [(Growth, Int)] = high
            ? [(.slow, highSlowWeight), (.med, highMedWeight), (.fast, highFastWeight)]
            : [(.slow, modestSlowWeight), (.med, modestMedWeight), (.fast, modestFastWeight)]
        return pick(options, using: &generator)
    }

    private func pick<T>(_ options: [(T, Int)], using generator: inout SeededGenerator) -> T {
        let weights = options.map { max(0, $0.1) }
        let total = max(weights.reduce(0, +), 1)
        var draw = Int.random(in: 0..<total, using: &generator)
        for (option, weight) in zip(options.map(\.0), weights) where weight > 0 {
            if draw < weight { return option }
            draw -= weight
        }
        return options[0].0
    }

    /// Experience already on the clock when the player is drafted. Below the first skill, and different for each id.
    func openingXP(for playerID: String) -> Int {
        let span = max(xpForFirstSkill, 1)
        return Int(Self.mix(playerID, salt: 0x5850) % UInt64(span))
    }

    /// Thousandths of a condition point this player loses per start.
    /// One point at the low end, `fitnessLossPerStart` at the high end. Never the old three-point drop.
    func fitnessDrainMilli(for playerID: String) -> Int {
        let ceiling = max(fitnessLossPerStart, 1) * 1000
        let floor = 1000
        if ceiling <= floor { return floor }
        let span = ceiling - floor + 1
        return floor + Int(Self.mix(playerID, salt: 0x4649) % UInt64(span))
    }

    /// Condition at the draft. Still green, and not the same number for the whole side.
    func openingCondition(for playerID: String) -> Int {
        let room = max(100 - greenMinimum, 1)
        let span = max(room / 2, 1)
        let offset = Int(Self.mix(playerID, salt: 0x434F) % UInt64(span))
        return 100 - offset
    }

    private static func mix(_ text: String, salt: UInt64) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037 ^ salt
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        hash &+= 0x9E37_79B9_7F4A_7C15
        var mixed = hash
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    var skillChoices: [SkillChoice] {
        PlayerStat.allCases.map { stat in
            SkillChoice(stat: stat, points: points(for: stat))
        }
    }
}
