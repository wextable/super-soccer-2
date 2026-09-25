import Foundation

/// Counting totals for one player across the weeks already played.
enum SeasonTotals {
    static func adding(
        _ tallies: [LeagueLeaders.Tally],
        to totals: [String: LeagueLeaders.Counts]
    ) -> [String: LeagueLeaders.Counts] {
        var next = totals
        for tally in tallies where tally.goals + tally.assists + tally.saves > 0 {
            var counts = next[tally.playerID] ?? LeagueLeaders.Counts()
            counts.goals += tally.goals
            counts.assists += tally.assists
            counts.saves += tally.saves
            next[tally.playerID] = counts
        }
        return next
    }
}

enum AwardKind: String, Equatable, Sendable, CaseIterable, Identifiable {
    case mvp
    case bestKeeper
    case bestDefender
    case bestMidfielder
    case bestForward
    case goldenBoot

    var id: AwardKind { self }

    var title: String {
        switch self {
        case .mvp: "MVP"
        case .bestKeeper: "Best keeper"
        case .bestDefender: "Best defender"
        case .bestMidfielder: "Best midfielder"
        case .bestForward: "Best forward"
        case .goldenBoot: "Golden boot"
        }
    }
}

/// One winner and the season stats already recorded for that player.
struct Award: Equatable, Sendable, Identifiable {
    var kind: AwardKind
    var player: Player
    var clubID: String
    var clubName: String
    var stats: LeagueLeaders.Counts

    var id: AwardKind { kind }
}

/// Champion and awards for one finished season. A later history screen can keep a list of these.
struct SeasonRecord: Equatable, Sendable {
    var championClubID: String
    var championName: String
    var awards: [Award]
}

enum SeasonAwards {
    /// The only season line. Forwards are 3 a goal and 2 an assist. Midfielders are 3 an assist and 2 a goal. Defenders are 2 a goal and 2 an assist. Keepers are a save.
    static func line(position: Position, counts: LeagueLeaders.Counts) -> Int {
        switch position {
        case .forward:
            counts.goals * 3 + counts.assists * 2
        case .midfielder:
            counts.assists * 3 + counts.goals * 2
        case .defender:
            counts.goals * 2 + counts.assists * 2
        case .keeper:
            counts.saves
        }
    }

    static func make(
        clubs: [Club],
        table: [Standing],
        totals: [String: LeagueLeaders.Counts]
    ) -> SeasonRecord? {
        guard let championID = table.first?.clubID,
              let champion = clubs.first(where: { $0.id == championID })
        else { return nil }

        let players = clubs.flatMap { club in
            club.starters.map { player in
                Candidate(
                    player: player,
                    clubID: club.id,
                    clubName: club.name,
                    stats: totals[player.id] ?? LeagueLeaders.Counts()
                )
            }
        }
        let awards = AwardKind.allCases.compactMap { winner($0, from: players) }
        guard awards.count == AwardKind.allCases.count else { return nil }
        return SeasonRecord(
            championClubID: champion.id,
            championName: champion.name,
            awards: awards
        )
    }

    private struct Candidate {
        var player: Player
        var clubID: String
        var clubName: String
        var stats: LeagueLeaders.Counts
    }

    private static func winner(_ kind: AwardKind, from players: [Candidate]) -> Award? {
        let pool: [Candidate]
        switch kind {
        case .bestKeeper:
            pool = players.filter { $0.player.position == .keeper }
        case .bestDefender:
            pool = players.filter { $0.player.position == .defender }
        case .bestMidfielder:
            pool = players.filter { $0.player.position == .midfielder }
        case .bestForward:
            pool = players.filter { $0.player.position == .forward }
        case .mvp, .goldenBoot:
            pool = players
        }
        guard let top = pool.sorted(by: { outranks($0, $1, kind: kind) }).first else { return nil }
        return Award(
            kind: kind,
            player: top.player,
            clubID: top.clubID,
            clubName: top.clubName,
            stats: top.stats
        )
    }

    /// True when `lhs` should place above `rhs`.
    private static func outranks(_ lhs: Candidate, _ rhs: Candidate, kind: AwardKind) -> Bool {
        switch kind {
        case .goldenBoot:
            return ahead(lhs.stats.goals, rhs.stats.goals)
                ?? ahead(lhs.stats.assists, rhs.stats.assists)
                ?? ahead(lhs.stats.saves, rhs.stats.saves)
                ?? earlierName(lhs, rhs)
        case .bestKeeper:
            return ahead(lhs.stats.saves, rhs.stats.saves)
                ?? ahead(lhs.stats.goals, rhs.stats.goals)
                ?? ahead(lhs.stats.assists, rhs.stats.assists)
                ?? earlierName(lhs, rhs)
        case .mvp, .bestDefender, .bestMidfielder, .bestForward:
            return ahead(line(position: lhs.player.position, counts: lhs.stats), line(position: rhs.player.position, counts: rhs.stats))
                ?? ahead(lhs.stats.goals, rhs.stats.goals)
                ?? ahead(lhs.stats.assists, rhs.stats.assists)
                ?? ahead(lhs.stats.saves, rhs.stats.saves)
                ?? earlierName(lhs, rhs)
        }
    }

    private static func ahead(_ lhs: Int, _ rhs: Int) -> Bool? {
        if lhs == rhs { return nil }
        return lhs > rhs
    }

    private static func earlierName(_ lhs: Candidate, _ rhs: Candidate) -> Bool {
        if lhs.player.fullName != rhs.player.fullName {
            return lhs.player.fullName < rhs.player.fullName
        }
        return lhs.player.id < rhs.player.id
    }
}
