import Foundation

enum Matchweek {
    struct Scoreline: Equatable, Sendable, Identifiable {
        var homeID: String
        var awayID: String
        var homeScore: Int
        var awayScore: Int

        var id: String { "\(homeID)-\(awayID)" }

        func involves(_ clubID: String) -> Bool {
            homeID == clubID || awayID == clubID
        }
    }

    struct Played: Equatable, Sendable {
        var scorelines: [Scoreline]
        var tallies: [LeagueLeaders.Tally]
        var userMatch: MatchResult
        var home: Club
        var away: Club
    }

    /// One draw covers the week. The week index keeps a repeated draw from replaying the same ten matches.
    static func weekSeed(draw: UInt64, weekIndex: Int) -> UInt64 {
        draw &+ UInt64(weekIndex) &* 1_000
    }

    static func play(
        fixtures: [LeagueDraft.Fixture],
        clubs: [Club],
        userClubID: String,
        seed: UInt64
    ) -> Played? {
        let clubsByID = Dictionary(uniqueKeysWithValues: clubs.map { ($0.id, $0) })
        var scorelines: [Scoreline] = []
        var tallies: [LeagueLeaders.Tally] = []
        var userMatch: MatchResult?
        var homeClub: Club?
        var awayClub: Club?
        for (index, fixture) in fixtures.enumerated() {
            guard let home = clubsByID[fixture.homeID], let away = clubsByID[fixture.awayID] else { return nil }
            let result = MatchSimulator.simulate(home: home, away: away, seed: seed &+ UInt64(index))
            scorelines.append(
                Scoreline(
                    homeID: home.id,
                    awayID: away.id,
                    homeScore: result.homeScore,
                    awayScore: result.awayScore
                )
            )
            tallies.append(contentsOf: LeagueLeaders.tally(home: home, away: away, result: result))
            if fixture.homeID == userClubID || fixture.awayID == userClubID {
                userMatch = result
                homeClub = home
                awayClub = away
            }
        }
        guard let userMatch, let homeClub, let awayClub else { return nil }
        return Played(
            scorelines: scorelines,
            tallies: tallies,
            userMatch: userMatch,
            home: homeClub,
            away: awayClub
        )
    }
}
