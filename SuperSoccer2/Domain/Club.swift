import Foundation

struct KitColor: Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
}

struct Kit: Equatable, Sendable {
    var primary: KitColor
    var secondary: KitColor
}

struct Club: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var shortName: String
    var nickname: String
    var kit: Kit
    var starters: [Player]

    var keeper: Player {
        starters.first { $0.position == .keeper } ?? starters[0]
    }

    var overall: Int {
        guard !starters.isEmpty else { return 0 }
        return starters.reduce(0) { $0 + $1.overall } / starters.count
    }

    var attack: Int {
        TeamRatings.attack(starters)
    }

    var defense: Int {
        TeamRatings.defense(starters)
    }

    var summaryLine: String {
        "Attack \(attack)  ·  Defense \(defense)"
    }
}

enum TeamRatings {
    private static let offset = 40
    private static let exponent = 1.21

    /// Starters only. Surplus above 40, raised to 1.21, then position weights, divided by 20.
    static func attack(_ starters: [Player]) -> Int {
        var rating = 0
        for player in starters {
            let weight: Double
            switch player.position {
            case .forward: weight = 2.85
            case .midfielder: weight = 2.0
            case .defender: weight = 1.15
            case .keeper: continue
            }
            let scoring = player.scoring
            if scoring > offset {
                rating += Int(pow(Double(scoring - offset), exponent) * weight)
            }
        }
        return Int(Double(rating) / 20.0)
    }

    /// Keeper contributes his overall, not the defensive blend. Divided by 24.
    static func defense(_ starters: [Player]) -> Int {
        var rating = 0
        for player in starters {
            switch player.position {
            case .forward:
                rating += weighted(player.defensive, weight: 1.2)
            case .midfielder:
                rating += weighted(player.defensive, weight: 2.0)
            case .defender:
                rating += weighted(player.defensive, weight: 2.8)
            case .keeper:
                rating += weighted(player.overall, weight: 4.0)
            }
        }
        return Int(Double(rating) / 24.0)
    }

    private static func weighted(_ value: Int, weight: Double) -> Int {
        guard value > offset else { return 0 }
        return Int(pow(Double(value - offset), exponent) * weight)
    }
}
