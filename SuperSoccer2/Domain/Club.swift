import Foundation

struct KitColor: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
}

struct Kit: Codable, Equatable, Sendable {
    var primary: KitColor
    var secondary: KitColor
}

struct Club: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    /// Three-letter code used on the scoreboard.
    var shortName: String
    /// Readable week-list name, such as “Man City” or “Norwich”. Not the three-letter code.
    var listName: String
    var nickname: String
    var kit: Kit
    /// The whole squad. Starters are the ones flagged to play.
    var players: [Player]

    var starters: [Player] {
        players.filter(\.isStarter)
    }

    var bench: [Player] {
        players.filter { !$0.isStarter }
    }

    /// Starting, then the bench. The club screen lists the squad in this order.
    var listedPlayers: [Player] {
        starters + bench
    }

    var keeper: Player {
        starters.first { $0.position == .keeper } ?? starters[0]
    }

    /// One line per injured player. The club shows these. There is no separate injury screen.
    var injuryLines: [String] {
        players.compactMap { player in
            guard let injury = player.injury else { return nil }
            let weeks = injury.weeksLeft == 1 ? "1 week" : "\(injury.weeksLeft) weeks"
            return "\(player.fullName) · \(injury.label) · \(weeks)"
        }
        .sorted()
    }

    /// Summary of the attack and defense the match uses. Not the average of the eleven player overalls.
    var overall: Int {
        Self.overall(attack: attack, defense: defense)
    }

    static func overall(attack: Int, defense: Int) -> Int {
        let mean = (Double(attack + defense) / 2).rounded()
        return min(99, max(1, Int(mean)))
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

    /// Prestige of this squad, in half stars from 1 to 5.
    var prestigeStars: Double {
        Self.prestigeStars(overall: overall)
    }

    /// Perceived goodness, not a line from overall 0–99 onto the star scale.
    /// An overall around 50 is very bad and is 1 star. The steps sit on the band
    /// this league actually rolls, about 64 to 87, so the twenty clubs spread
    /// across the scale instead of stacking on one or two values.
    static func prestigeStars(overall: Int) -> Double {
        switch overall {
        case ..<66: 1
        case 66..<69: 1.5
        case 69..<72: 2
        case 72..<74: 2.5
        case 74..<76: 3
        case 76..<79: 3.5
        case 79..<82: 4
        case 82..<85: 4.5
        default: 5
        }
    }

    static func prestigeLabel(stars: Double) -> String {
        if stars == 1 { return "1 star" }
        if stars == stars.rounded(.down) { return "\(Int(stars)) stars" }
        return "\(stars) stars"
    }

    /// Highest prestige first. The same star rating keeps alphabetical order.
    static func prestigeOrder(_ lhs: Club, _ rhs: Club) -> Bool {
        if lhs.prestigeStars != rhs.prestigeStars {
            return lhs.prestigeStars > rhs.prestigeStars
        }
        return lhs.name < rhs.name
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
