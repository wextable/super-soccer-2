import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct SeasonHarnessTests {
    @Test func draftTiersMatchThePreviousRounds() {
        #expect(LeagueDraft.draftingCount(round: 1, clubs: 20) == 6)
        #expect(LeagueDraft.draftingCount(round: 2, clubs: 20) == 6)
        #expect(LeagueDraft.draftingCount(round: 3, clubs: 20) == 12)
        #expect(LeagueDraft.draftingCount(round: 4, clubs: 20) == 15)
        #expect(LeagueDraft.draftingCount(round: 5, clubs: 20) == 15)
        #expect(LeagueDraft.draftingCount(round: 6, clubs: 20) == 20)
    }

    @Test func aSeededDraftFillsTheLeagueAndRepeats() {
        let season = LeagueDraft.makeLeague(seed: 42)
        #expect(season == LeagueDraft.makeLeague(seed: 42))
        #expect(season.clubs.map(\.name).first == "Manchester City")
        #expect(season.clubs.map(\.name).last == "Norwich City")
        #expect(season.rosterCounts == Array(repeating: 20, count: 20))
        #expect(season.fixtures.count == 380)

        for club in season.clubs {
            #expect(club.starters.count == 11)
            #expect(club.starters.filter { $0.position == .keeper }.count == 1)
            let outfield = club.starters.filter { $0.position != .keeper }
            let lineCounts = Dictionary(grouping: outfield, by: \.position).map(\.value.count).sorted()
            #expect(lineCounts == [3, 3, 4])
        }

        var games: [String: Int] = [:]
        var meetings: [String: (home: String, count: Int)] = [:]
        for fixture in season.fixtures {
            games[fixture.homeID, default: 0] += 1
            games[fixture.awayID, default: 0] += 1
            let key = [fixture.homeID, fixture.awayID].sorted().joined(separator: "/")
            if var existing = meetings[key] {
                #expect(existing.home == fixture.homeID)
                existing.count += 1
                meetings[key] = existing
            } else {
                meetings[key] = (fixture.homeID, 1)
            }
        }
        #expect(games.values.allSatisfy { $0 == 38 })
        #expect(meetings.count == 190)
        #expect(meetings.values.allSatisfy { $0.count == 2 })
        #expect(season.clubs[0].overall > season.clubs[19].overall)
    }

    @Test func shippedConstantsLetALateClubScore() {
        #expect(MatchTuning.current == .shipped)
        let audit = SeasonHarness.play(seasons: 20, seed: 20240924)
        #expect(audit == SeasonHarness.play(seasons: 20, seed: 20240924))
        print(audit.text)
        #expect(audit.matches == 20 * 380)
        #expect(audit.meanOverall[0] > audit.meanOverall[19] + 4)
        #expect(audit.meanGoalsFor[0] > audit.meanGoalsFor[19] * 2)
        #expect(audit.weakerSideScoredShare > 0.30)
        #expect(audit.norwichScoredShare > 0.30)
        #expect(audit.lateVersusEarlyScoredShare > 0.08)
        #expect(audit.nilNilRate < 0.12)
        #expect(audit.blowoutRate < 0.30)
        #expect(audit.meanTopScorerGoals > 8)
    }
}
