import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct SeasonAwardsTests {
    @Test func theLinePicksEachAwardFromGoalsAssistsAndSaves() throws {
        let season = LeagueDraft.makeLeague(seed: 1)
        let starters = season.clubs.flatMap(\.starters)
        let forwardA = try #require(starters.first { $0.position == .forward })
        let forwardB = try #require(starters.first { $0.position == .forward && $0.id != forwardA.id })
        let midfielder = try #require(starters.first { $0.position == .midfielder })
        let keeper = try #require(starters.first { $0.position == .keeper })
        let otherKeeper = try #require(starters.first { $0.position == .keeper && $0.id != keeper.id })
        let defenders = starters
            .filter { $0.position == .defender }
            .sorted { lhs, rhs in
                if lhs.fullName != rhs.fullName { return lhs.fullName < rhs.fullName }
                return lhs.id < rhs.id
            }
        let defenderA = try #require(defenders.first)
        let defenderB = try #require(defenders.dropFirst().first)
        #expect(defenderA.fullName < defenderB.fullName || defenderA.id < defenderB.id)

        #expect(SeasonAwards.line(position: .forward, counts: counts(goals: 2, saves: 99)) == 6)
        #expect(SeasonAwards.line(position: .forward, counts: counts(goals: 1, assists: 2)) == 7)
        #expect(SeasonAwards.line(position: .midfielder, counts: counts(assists: 5)) == 15)
        #expect(SeasonAwards.line(position: .defender, counts: counts(goals: 1, assists: 1)) == 4)
        #expect(SeasonAwards.line(position: .keeper, counts: counts(saves: 9)) == 9)

        var totals: [String: LeagueLeaders.Counts] = [:]
        totals[forwardA.id] = counts(goals: 2, saves: 99)
        totals[forwardB.id] = counts(goals: 1, assists: 2)
        totals[midfielder.id] = counts(assists: 5)
        totals[keeper.id] = counts(saves: 4)
        totals[otherKeeper.id] = counts(saves: 9)
        totals[defenderA.id] = counts(goals: 1, assists: 1)
        totals[defenderB.id] = counts(goals: 1, assists: 1)

        var rows = LeagueTable.zeros(clubIDs: season.clubs.map(\.id))
        rows = rows.map { row in
            var copy = row
            if row.clubID == "manchester-city" {
                copy.played = 1
                copy.points = 10
            }
            return copy
        }
        let record = try #require(
            SeasonAwards.make(
                clubs: season.clubs,
                table: LeagueTable.ranked(rows, clubs: season.clubs),
                totals: totals
            )
        )
        #expect(record.championClubID == "manchester-city")
        #expect(record.championName == "Manchester City")
        #expect(record.awards.map(\.kind) == AwardKind.allCases)

        let awards = Dictionary(uniqueKeysWithValues: record.awards.map { ($0.kind, $0) })
        #expect(awards[.goldenBoot]?.player.id == forwardA.id)
        #expect(awards[.goldenBoot]?.stats.goals == 2)
        #expect(awards[.bestForward]?.player.id == forwardB.id)
        #expect(awards[.bestMidfielder]?.player.id == midfielder.id)
        #expect(awards[.bestDefender]?.player.id == defenderA.id)
        #expect(awards[.bestKeeper]?.player.id == otherKeeper.id)
        #expect(awards[.bestKeeper]?.player.position == .keeper)
        #expect(awards[.mvp]?.player.id == midfielder.id)
        #expect(awards[.mvp]?.stats == counts(assists: 5))
    }

    @Test func aFinishedSeasonNamesAChampionAndTheSixAwards() throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let weeks = LeagueDraft.weeks(in: season.fixtures)
        #expect(weeks.count == 38)
        #expect(weeks.allSatisfy { $0.count == 10 })

        var standings = LeagueTable.zeros(clubIDs: season.clubs.map(\.id))
        var totals: [String: LeagueLeaders.Counts] = [:]
        for (weekIndex, fixtures) in weeks.enumerated() {
            let played = try #require(
                Matchweek.play(
                    fixtures: fixtures,
                    clubs: season.clubs,
                    userClubID: "manchester-city",
                    seed: Matchweek.weekSeed(draw: 42, weekIndex: weekIndex)
                )
            )
            standings = LeagueTable.applying(played.scorelines, to: standings)
            totals = SeasonTotals.adding(played.tallies, to: totals)
        }

        let table = LeagueTable.ranked(standings, clubs: season.clubs)
        let champion = try #require(table.first)
        let record = try #require(SeasonAwards.make(clubs: season.clubs, table: table, totals: totals))
        let championClub = try #require(season.clubs.first { $0.id == champion.clubID })
        #expect(record.championClubID == champion.clubID)
        #expect(record.championName == championClub.name)
        #expect(record.awards.map(\.kind) == AwardKind.allCases)

        let starters = season.clubs.flatMap(\.starters)
        let awards = Dictionary(uniqueKeysWithValues: record.awards.map { ($0.kind, $0) })
        for award in record.awards {
            #expect(award.stats == (totals[award.player.id] ?? LeagueLeaders.Counts()))
            #expect(starters.contains { $0.id == award.player.id })
        }

        let boot = try #require(awards[.goldenBoot])
        #expect(boot.stats.goals == starters.map { totals[$0.id]?.goals ?? 0 }.max())

        let keeper = try #require(awards[.bestKeeper])
        let keepers = starters.filter { $0.position == .keeper }
        #expect(keeper.player.position == .keeper)
        #expect(keeper.stats.saves == keepers.map { totals[$0.id]?.saves ?? 0 }.max())

        try expectLineAward(.bestForward, position: .forward, awards: awards, starters: starters, totals: totals)
        try expectLineAward(.bestMidfielder, position: .midfielder, awards: awards, starters: starters, totals: totals)
        try expectLineAward(.bestDefender, position: .defender, awards: awards, starters: starters, totals: totals)

        let mvp = try #require(awards[.mvp])
        let mvpLine = SeasonAwards.line(position: mvp.player.position, counts: mvp.stats)
        let bestLine = starters.map { SeasonAwards.line(position: $0.position, counts: totals[$0.id] ?? LeagueLeaders.Counts()) }.max()
        #expect(mvpLine == bestLine)
    }
}

private func counts(goals: Int = 0, assists: Int = 0, saves: Int = 0) -> LeagueLeaders.Counts {
    LeagueLeaders.Counts(goals: goals, assists: assists, saves: saves)
}

private func expectLineAward(
    _ kind: AwardKind,
    position: Position,
    awards: [AwardKind: Award],
    starters: [Player],
    totals: [String: LeagueLeaders.Counts]
) throws {
    let award = try #require(awards[kind])
    #expect(award.player.position == position)
    let winner = SeasonAwards.line(position: award.player.position, counts: award.stats)
    let best = starters
        .filter { $0.position == position }
        .map { SeasonAwards.line(position: $0.position, counts: totals[$0.id] ?? LeagueLeaders.Counts()) }
        .max()
    #expect(winner == best)
}
