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
    /// Experience for the first skill. Later skills cost this plus `extraXpPerSkill` times skills already earned.
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
        injuryWeeksMax: 3
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

    func requiredXP(skillsEarned: Int) -> Int {
        xpForFirstSkill + extraXpPerSkill * skillsEarned
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
