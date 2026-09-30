import Foundation

enum Position: String, Codable, Equatable, Sendable, CaseIterable {
    case keeper
    case defender
    case midfielder
    case forward

    var label: String {
        switch self {
        case .keeper: "GK"
        case .defender: "DEF"
        case .midfielder: "MID"
        case .forward: "FWD"
        }
    }

    var title: String {
        switch self {
        case .keeper: "Keeper"
        case .defender: "Defender"
        case .midfielder: "Midfielder"
        case .forward: "Forward"
        }
    }

    init?(labeled name: String) {
        if let match = Self.allCases.first(where: { $0.title == name || $0.label == name }) {
            self = match
        } else {
            return nil
        }
    }
}

struct Ratings: Codable, Equatable, Sendable {
    var speed: Int
    var shooting: Int
    var passing: Int
    var dribbling: Int
    var defending: Int
    var goalkeeping: Int

    func overall(for position: Position) -> Int {
        let value: Double
        switch position {
        case .keeper:
            value = Double(speed) * 0.01
                + Double(shooting) * 0.01
                + Double(passing) * 0.1
                + Double(dribbling) * 0.02
                + Double(defending) * 0.25
                + Double(goalkeeping) * 0.61
        case .defender:
            value = Double(speed) * 0.18
                + Double(shooting) * 0.02
                + Double(passing) * 0.15
                + Double(dribbling) * 0.05
                + Double(defending) * 0.6
        case .midfielder:
            value = Double(speed) * 0.22
                + Double(shooting) * 0.18
                + Double(passing) * 0.26
                + Double(dribbling) * 0.2
                + Double(defending) * 0.14
                + 2
        case .forward:
            value = Double(speed) * 0.3
                + Double(shooting) * 0.3
                + Double(passing) * 0.1
                + Double(dribbling) * 0.28
                + Double(defending) * 0.02
        }
        return Int(value)
    }

    var scoring: Int {
        Int(
            Double(shooting) * 0.4
                + Double(speed) * 0.3
                + Double(dribbling) * 0.25
                + Double(passing) * 0.05
        )
    }

    var defensive: Int {
        Int(
            Double(defending) * 0.6
                + Double(speed) * 0.25
                + Double(dribbling) * 0.05
                + Double(passing) * 0.1
        )
    }

    var assist: Int {
        Int(
            Double(speed) * 0.4
                + Double(dribbling) * 0.25
                + Double(passing) * 0.35
        )
    }

    func value(for stat: PlayerStat) -> Int {
        switch stat {
        case .speed: speed
        case .shooting: shooting
        case .passing: passing
        case .dribbling: dribbling
        case .defending: defending
        case .goalkeeping: goalkeeping
        }
    }

    mutating func set(_ stat: PlayerStat, to value: Int) {
        switch stat {
        case .speed: speed = value
        case .shooting: shooting = value
        case .passing: passing = value
        case .dribbling: dribbling = value
        case .defending: defending = value
        case .goalkeeping: goalkeeping = value
        }
    }
}

/// How quickly a week's experience reaches the next level.
/// The player screen does not name these. The experience bar is the pace.
enum Growth: String, Codable, Equatable, Sendable {
    case slow
    case med
    case fast
}

/// One ceiling for each attribute, from 1 to 99. The current rating never passes it.
struct Potential: Codable, Equatable, Sendable {
    var speed: Int
    var shooting: Int
    var passing: Int
    var dribbling: Int
    var defending: Int
    var goalkeeping: Int

    func value(for stat: PlayerStat) -> Int {
        switch stat {
        case .speed: speed
        case .shooting: shooting
        case .passing: passing
        case .dribbling: dribbling
        case .defending: defending
        case .goalkeeping: goalkeeping
        }
    }

    var highest: Int {
        max(speed, max(shooting, max(passing, max(dribbling, max(defending, goalkeeping)))))
    }

    /// Every attribute can reach 99.
    static let open = Potential(
        speed: 99,
        shooting: 99,
        passing: 99,
        dribbling: 99,
        defending: 99,
        goalkeeping: 99
    )
}

struct Player: Codable, Equatable, Sendable, Identifiable {
    struct Injury: Codable, Equatable, Sendable {
        var label: String
        var weeksLeft: Int
        /// What happened. An opponent and the challenge, not only the ailment.
        var cause: String = ""
    }

    var id: String
    var firstName: String
    var lastName: String
    var position: Position
    var condition: Int
    /// Set during the tier draft. The match reads starters only.
    var isStarter: Bool = false
    var ratings: Ratings
    /// Years. Shown on the player screen. It does not pull ratings down.
    var age: Int = WeekTuning.missingAge
    /// The ceiling for each attribute. The rating stops here instead of at a flat 99.
    var potential: Potential = .open
    /// Stored pace for the experience earned this week. Not a label on the player screen.
    var growth: Growth = .med
    var xp: Int = 0
    /// Levels already earned. The next level costs more than this one.
    var level: Int = 0
    /// Skills already spent. The next skill costs more.
    var skillsEarned: Int = 0
    var injury: Injury? = nil
    /// Thousandths of a condition point still to come off. Personal drain uses this.
    var fitnessDebt: Int = 0
    /// Portrait parts from the old face factory. The screen paints them. The bitmap is not saved.
    var face: PlayerFace = .plain

    var fullName: String {
        if firstName.isEmpty {
            return lastName
        }
        return "\(firstName) \(lastName)"
    }

    /// The blend at full fitness. The match uses `overall`, which is this after the band scale.
    var optimalOverall: Int {
        ratings.overall(for: position)
    }

    /// Integer blend, then the fitness-band scale. Green leaves the blend unchanged.
    var overall: Int {
        adjusted(optimalOverall)
    }

    func fitnessBand(tuning: WeekTuning = .current) -> FitnessBand {
        tuning.band(for: condition)
    }

    var scoring: Int {
        adjusted(ratings.scoring)
    }

    var defensive: Int {
        adjusted(ratings.defensive)
    }

    var assist: Int {
        adjusted(ratings.assist)
    }

    /// This stat after the fitness-band scale. Green leaves the full-fitness number unchanged.
    func playingRating(_ stat: PlayerStat) -> Int {
        adjusted(ratings.value(for: stat))
    }

    private func adjusted(_ rating: Int) -> Int {
        let scale = WeekTuning.current.ratingScale(for: fitnessBand())
        return Int(Double(rating) * scale)
    }

    /// True when at least one attribute is still under its ceiling.
    var canGrow: Bool {
        PlayerStat.allCases.contains { ratings.value(for: $0) < potential.value(for: $0) }
    }
}

