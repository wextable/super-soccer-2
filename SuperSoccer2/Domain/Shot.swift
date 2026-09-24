import Foundation

enum ShotType: String, Equatable, Sendable {
    case regular
    case penalty
}

enum ShotResult: String, Equatable, Sendable {
    case goal
    case miss
    case save
}

struct Shot: Equatable, Sendable, Identifiable {
    var id: Int
    var type: ShotType
    var result: ShotResult
    var shooter: Player
    var passer: Player?
    var keeper: Player
    var minute: Int
    var isHome: Bool
}

struct MatchResult: Equatable, Sendable {
    var homeScore: Int
    var awayScore: Int
    var shots: [Shot]
    var highlight: Shot
    var commentary: String
    var seed: UInt64
}

enum Commentary {
    static func line(shot: Shot, attackingClub: String, defendingClub: String) -> String {
        let shooter = shot.shooter.fullName
        let penalty = shot.type == .penalty ? "Penalty. " : ""
        switch shot.result {
        case .goal:
            if let passer = shot.passer {
                return "\(penalty)\(shooter) of \(attackingClub) scores from \(passer.fullName)."
            }
            return "\(penalty)\(shooter) of \(attackingClub) scores."
        case .save:
            let approach: String
            if let passer = shot.passer {
                approach = "\(passer.fullName) plays in \(shooter) of \(attackingClub)."
            } else {
                approach = "\(shooter) of \(attackingClub) shoots."
            }
            return "\(penalty)\(approach) \(shot.keeper.fullName) saves for \(defendingClub)."
        case .miss:
            if let passer = shot.passer {
                return "\(penalty)\(passer.fullName) finds \(shooter) of \(attackingClub), who misses."
            }
            return "\(penalty)\(shooter) of \(attackingClub) misses."
        }
    }
}
