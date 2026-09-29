import Foundation

struct Standing: Codable, Equatable, Sendable, Identifiable {
    var clubID: String
    var played: Int
    var won: Int
    var drawn: Int
    var lost: Int
    var points: Int
    var goalsFor: Int
    var goalsAgainst: Int

    var id: String { clubID }
    var goalDifference: Int { goalsFor - goalsAgainst }
    /// Wins, losses, then draws. The table column.
    var recordLine: String { "\(won)/\(lost)/\(drawn)" }

    init(
        clubID: String,
        played: Int,
        won: Int = 0,
        drawn: Int = 0,
        lost: Int = 0,
        points: Int,
        goalsFor: Int,
        goalsAgainst: Int
    ) {
        self.clubID = clubID
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.points = points
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }
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

    /// `1st`, `2nd`, `3rd`, `4th`, with the teens staying `11th`.
    static func placeWord(_ place: Int) -> String {
        let tens = place % 100
        if (11...13).contains(tens) { return "\(place)th" }
        switch place % 10 {
        case 1: return "\(place)st"
        case 2: return "\(place)nd"
        case 3: return "\(place)rd"
        default: return "\(place)th"
        }
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
            won += 1
            points += 3
        } else if scored == conceded {
            drawn += 1
            points += 1
        } else {
            lost += 1
        }
    }
}
