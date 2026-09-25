import Foundation

struct Standing: Equatable, Sendable, Identifiable {
    var clubID: String
    var played: Int
    var points: Int
    var goalsFor: Int
    var goalsAgainst: Int

    var id: String { clubID }
    var goalDifference: Int { goalsFor - goalsAgainst }
}

enum LeagueTable {
    static func zeros(clubIDs: [String]) -> [Standing] {
        clubIDs.map { Standing(clubID: $0, played: 0, points: 0, goalsFor: 0, goalsAgainst: 0) }
    }

    static func applying(_ scorelines: [Matchweek.Scoreline], to standings: [Standing]) -> [Standing] {
        var rows = Dictionary(uniqueKeysWithValues: standings.map { ($0.clubID, $0) })
        for line in scorelines {
            rows[line.homeID]?.record(scored: line.homeScore, conceded: line.awayScore)
            rows[line.awayID]?.record(scored: line.awayScore, conceded: line.homeScore)
        }
        return standings.map { rows[$0.clubID] ?? $0 }
    }

    /// Points, then goal difference, then the club's overall. A remaining tie keeps the earlier row.
    static func ranked(_ standings: [Standing], clubs: [Club]) -> [Standing] {
        let overall = Dictionary(uniqueKeysWithValues: clubs.map { ($0.id, $0.overall) })
        return standings.sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.goalDifference != rhs.goalDifference { return lhs.goalDifference > rhs.goalDifference }
            return (overall[lhs.clubID] ?? 0) > (overall[rhs.clubID] ?? 0)
        }
    }
}

private extension Standing {
    mutating func record(scored: Int, conceded: Int) {
        played += 1
        goalsFor += scored
        goalsAgainst += conceded
        if scored > conceded {
            points += 3
        } else if scored == conceded {
            points += 1
        }
    }
}
