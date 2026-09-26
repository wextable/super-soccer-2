import Foundation

/// How fit a player is for the next match. Green is full ratings. Red is the band you reach by playing through yellow.
enum FitnessBand: Equatable, Sendable {
    case green
    case yellow
    case red

    var label: String {
        switch self {
        case .green: "Green"
        case .yellow: "Yellow"
        case .red: "Red"
        }
    }

    /// A higher rank is fitter. Other clubs only bring in someone from a higher rank.
    var rank: Int {
        switch self {
        case .green: 2
        case .yellow: 1
        case .red: 0
        }
    }

    func isFitter(than other: FitnessBand) -> Bool {
        rank > other.rank
    }
}

/// One of the six ratings. A skill pick adds points to exactly one of these.
enum PlayerStat: String, Equatable, Sendable, CaseIterable, Identifiable {
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
struct SkillChoice: Equatable, Sendable, Identifiable {
    var stat: PlayerStat
    var points: Int

    var id: PlayerStat { stat }
}

/// One player earned one skill. The stat is still unspent until someone picks it.
struct SkillOffer: Equatable, Sendable, Identifiable {
    var id: String
    var playerID: String
    var clubID: String
}

/// Weights for the week between matches. A later settings screen can bind each field.
/// The goal-mean constants stay on `MatchTuning`.
struct WeekTuning: Equatable, Sendable {
    /// Fitness a starter loses after the match.
    var fitnessLossPerStart: Int
    /// Fitness a healthy unused player gains. One week of this clears most of a run into the red.
    var benchRecovery: Int
    /// Condition at or above this is green.
    var greenMinimum: Int
    /// Condition at or above this, and below green, is yellow. Below this is red.
    var yellowMinimum: Int
    /// Percent chance a green starter is hurt. Negligible.
    var injuryChanceGreen: Int
    /// Percent chance a yellow starter is hurt. Milder than red.
    var injuryChanceYellow: Int
    /// Percent chance a red starter is hurt. High.
    var injuryChanceRed: Int
    /// Multiplier on the ratings the match already uses. Green leaves them alone.
    var ratingScaleGreen: Double
    var ratingScaleYellow: Double
    var ratingScaleRed: Double
    var xpForStart: Int
    var xpForGoal: Int
    var xpForAssist: Int
    var xpForSave: Int
    var xpForKeeperCleanSheet: Int
    var xpForDefenderCleanSheet: Int
    /// Experience for the first skill. Later skills cost this plus `extraXpPerSkill` times skills already earned.
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

    /// A month of starts stays green. Yellow takes a longer run. Red takes playing through that yellow.
    /// One bench week puts the first red week back in the green.
    static let current = WeekTuning(
        fitnessLossPerStart: 2,
        benchRecovery: 28,
        greenMinimum: 84,
        yellowMinimum: 64,
        injuryChanceGreen: 1,
        injuryChanceYellow: 6,
        injuryChanceRed: 40,
        ratingScaleGreen: 1,
        ratingScaleYellow: 0.96,
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
        return .red
    }

    func ratingScale(for band: FitnessBand) -> Double {
        switch band {
        case .green: ratingScaleGreen
        case .yellow: ratingScaleYellow
        case .red: ratingScaleRed
        }
    }

    func injuryChance(for band: FitnessBand) -> Int {
        switch band {
        case .green: injuryChanceGreen
        case .yellow: injuryChanceYellow
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

    var skillChoices: [SkillChoice] {
        PlayerStat.allCases.map { stat in
            SkillChoice(stat: stat, points: points(for: stat))
        }
    }
}
