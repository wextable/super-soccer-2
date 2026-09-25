import Foundation

/// Goals, assists, and saves taken from the shots the match already records.
enum LeagueLeaders {
    struct Counts: Equatable, Sendable {
        var goals: Int = 0
        var assists: Int = 0
        var saves: Int = 0
    }

    struct Tally: Equatable, Sendable {
        var playerID: String
        var clubID: String
        var goals: Int
        var assists: Int
        var saves: Int
    }

    struct Row: Equatable, Identifiable, Sendable {
        var player: Player
        var clubID: String
        var clubName: String
        var count: Int

        var id: String { player.id }
    }

    /// One match. A goal credits the shooter. A passer on that goal gets the assist. A save credits the keeper.
    static func tally(home: Club, away: Club, result: MatchResult) -> [Tally] {
        var rows: [String: Tally] = [:]
        for shot in result.shots {
            let attacking = shot.isHome ? home : away
            let defending = shot.isHome ? away : home
            switch shot.result {
            case .goal:
                add(shot.shooter, club: attacking, goals: 1, to: &rows)
                if let passer = shot.passer {
                    add(passer, club: attacking, assists: 1, to: &rows)
                }
            case .save:
                add(shot.keeper, club: defending, saves: 1, to: &rows)
            case .miss:
                break
            }
        }
        return rows.values.sorted { $0.playerID < $1.playerID }
    }

    private static func add(
        _ player: Player,
        club: Club,
        goals: Int = 0,
        assists: Int = 0,
        saves: Int = 0,
        to rows: inout [String: Tally]
    ) {
        var row = rows[player.id] ?? Tally(playerID: player.id, clubID: club.id, goals: 0, assists: 0, saves: 0)
        row.goals += goals
        row.assists += assists
        row.saves += saves
        rows[player.id] = row
    }
}
