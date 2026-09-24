import Foundation

enum Position: String, Equatable, Sendable, CaseIterable {
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
}

struct Ratings: Equatable, Sendable {
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
}

struct Player: Equatable, Sendable, Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var position: Position
    var condition: Int
    /// Set during the tier draft. The match reads starters only.
    var isStarter: Bool = false
    var ratings: Ratings

    var fullName: String {
        if firstName.isEmpty {
            return lastName
        }
        return "\(firstName) \(lastName)"
    }

    /// Integer blend, then the condition scale. Full fitness leaves the blend unchanged.
    var overall: Int {
        adjusted(ratings.overall(for: position))
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

    private func adjusted(_ rating: Int) -> Int {
        let effectiveness = 100 - ((100 - Double(condition)) * 0.1)
        return Int(Double(rating) * (effectiveness / 100))
    }
}
