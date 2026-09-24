import Foundation

/// Plays drafted seasons and records the distributions used to tune the goal mean.
/// Not a screen. The two-club app does not show this league.
enum SeasonHarness {
    struct Audit: Equatable, Sendable {
        var seasons: Int
        var matches: Int
        var tuning: MatchTuning
        var meanOverall: [Double]
        var meanAttack: [Double]
        var meanDefense: [Double]
        var meanGoalsFor: [Double]
        var meanGoalsAgainst: [Double]
        var scoredShare: [Double]
        var weakerSideScoredShare: Double
        var nilNilRate: Double
        var oneSidedCleanSheetRate: Double
        var blowoutRate: Double
        var marginThreePlusRate: Double
        var lateScoredShare: Double
        var lateVersusEarlyScoredShare: Double
        var norwichScoredShare: Double
        var norwichVersusCityScoredShare: Double
        var meanTopScorerGoals: Double

        var text: String {
            var lines: [String] = []
            lines.append(
                "tuning diff \(tuning.ratingDiffPerGoal) home \(tuning.homeFieldAdvantage) noise ±\(tuning.goalNoiseHalfWidth) base \(tuning.baseGoals)"
            )
            lines.append("seasons \(seasons) matches \(matches)")
            lines.append("idx  club                  ovr   atk   def    gf    ga   scored")
            for index in meanOverall.indices {
                let name = LeagueDraft.clubName(at: index).padding(toLength: 20, withPad: " ", startingAt: 0)
                lines.append(
                    String(
                        format: "%2d  %@ %5.1f %5.1f %5.1f %6.1f %5.1f   %4.0f%%",
                        index,
                        name,
                        meanOverall[index],
                        meanAttack[index],
                        meanDefense[index],
                        meanGoalsFor[index],
                        meanGoalsAgainst[index],
                        scoredShare[index] * 100
                    )
                )
            }
            lines.append(String(format: "weaker side scored %.1f%%", weakerSideScoredShare * 100))
            lines.append(String(format: "nil-nil %.1f%%", nilNilRate * 100))
            lines.append(String(format: "one-sided clean sheet %.1f%%", oneSidedCleanSheetRate * 100))
            lines.append(String(format: "blowout margin >= 4  %.1f%%", blowoutRate * 100))
            lines.append(String(format: "margin >= 3          %.1f%%", marginThreePlusRate * 100))
            lines.append(String(format: "late clubs (15-19) scored %.1f%% of their matches", lateScoredShare * 100))
            lines.append(String(format: "late vs early (0-5) scored %.1f%%", lateVersusEarlyScoredShare * 100))
            lines.append(String(format: "Norwich scored %.1f%%", norwichScoredShare * 100))
            lines.append(String(format: "Norwich vs City scored %.1f%%", norwichVersusCityScoredShare * 100))
            lines.append(String(format: "mean top scorer goals %.1f", meanTopScorerGoals))
            return lines.joined(separator: "\n")
        }
    }

    static func play(seasons: Int, seed: UInt64, tuning: MatchTuning = .current) -> Audit {
        let count = LeagueDraft.clubCount
        var overall = Array(repeating: 0, count: count)
        var attack = Array(repeating: 0, count: count)
        var defense = Array(repeating: 0, count: count)
        var goalsFor = Array(repeating: 0, count: count)
        var goalsAgainst = Array(repeating: 0, count: count)
        var clubMatches = Array(repeating: 0, count: count)
        var clubScored = Array(repeating: 0, count: count)
        var weakerChecks = 0
        var weakerScored = 0
        var nilNil = 0
        var oneSided = 0
        var blowouts = 0
        var marginThree = 0
        var totalMatches = 0
        var lateMatches = 0
        var lateScored = 0
        var lateEarlyMatches = 0
        var lateEarlyScored = 0
        var norwichMatches = 0
        var norwichScored = 0
        var norwichCityMatches = 0
        var norwichCityScored = 0
        var topScorerGoals = 0

        for seasonIndex in 0..<seasons {
            let seasonSeed = seed &+ UInt64(seasonIndex) &* 0x9E37_79B9_7F4A_7C15
            let season = LeagueDraft.makeLeague(seed: seasonSeed)
            let byID = Dictionary(uniqueKeysWithValues: season.clubs.enumerated().map { ($1.id, $0) })
            for index in season.clubs.indices {
                overall[index] += season.clubs[index].overall
                attack[index] += season.clubs[index].attack
                defense[index] += season.clubs[index].defense
            }

            var seasonGoals: [String: Int] = [:]
            for (matchIndex, fixture) in season.fixtures.enumerated() {
                guard let homeIndex = byID[fixture.homeID], let awayIndex = byID[fixture.awayID] else { continue }
                let home = season.clubs[homeIndex]
                let away = season.clubs[awayIndex]
                let matchSeed = seasonSeed &+ UInt64(matchIndex) &+ 1
                let result = MatchSimulator.simulate(home: home, away: away, seed: matchSeed, tuning: tuning)
                totalMatches += 1
                goalsFor[homeIndex] += result.homeScore
                goalsFor[awayIndex] += result.awayScore
                goalsAgainst[homeIndex] += result.awayScore
                goalsAgainst[awayIndex] += result.homeScore
                clubMatches[homeIndex] += 1
                clubMatches[awayIndex] += 1
                if result.homeScore > 0 { clubScored[homeIndex] += 1 }
                if result.awayScore > 0 { clubScored[awayIndex] += 1 }
                if result.homeScore == 0, result.awayScore == 0 { nilNil += 1 }
                if (result.homeScore == 0) != (result.awayScore == 0) { oneSided += 1 }
                let margin = abs(result.homeScore - result.awayScore)
                if margin >= 4 { blowouts += 1 }
                if margin >= 3 { marginThree += 1 }

                if home.overall != away.overall {
                    weakerChecks += 1
                    let weakerGoals = home.overall < away.overall ? result.homeScore : result.awayScore
                    if weakerGoals > 0 { weakerScored += 1 }
                }

                recordLate(
                    homeIndex: homeIndex,
                    awayIndex: awayIndex,
                    homeGoals: result.homeScore,
                    awayGoals: result.awayScore,
                    lateMatches: &lateMatches,
                    lateScored: &lateScored,
                    lateEarlyMatches: &lateEarlyMatches,
                    lateEarlyScored: &lateEarlyScored
                )
                if homeIndex == count - 1 || awayIndex == count - 1 {
                    norwichMatches += 1
                    let scored = homeIndex == count - 1 ? result.homeScore : result.awayScore
                    if scored > 0 { norwichScored += 1 }
                    let opponent = homeIndex == count - 1 ? awayIndex : homeIndex
                    if opponent == 0 {
                        norwichCityMatches += 1
                        if scored > 0 { norwichCityScored += 1 }
                    }
                }
                for shot in result.shots where shot.result == .goal {
                    seasonGoals[shot.shooter.id, default: 0] += 1
                }
            }
            topScorerGoals += seasonGoals.values.max() ?? 0
        }

        let seasonCount = Double(seasons)
        func share(_ hits: Int, _ attempts: Int) -> Double {
            guard attempts > 0 else { return 0 }
            return Double(hits) / Double(attempts)
        }
        return Audit(
            seasons: seasons,
            matches: totalMatches,
            tuning: tuning,
            meanOverall: overall.map { Double($0) / seasonCount },
            meanAttack: attack.map { Double($0) / seasonCount },
            meanDefense: defense.map { Double($0) / seasonCount },
            meanGoalsFor: goalsFor.map { Double($0) / seasonCount },
            meanGoalsAgainst: goalsAgainst.map { Double($0) / seasonCount },
            scoredShare: zip(clubScored, clubMatches).map { share($0, $1) },
            weakerSideScoredShare: share(weakerScored, weakerChecks),
            nilNilRate: share(nilNil, totalMatches),
            oneSidedCleanSheetRate: share(oneSided, totalMatches),
            blowoutRate: share(blowouts, totalMatches),
            marginThreePlusRate: share(marginThree, totalMatches),
            lateScoredShare: share(lateScored, lateMatches),
            lateVersusEarlyScoredShare: share(lateEarlyScored, lateEarlyMatches),
            norwichScoredShare: share(norwichScored, norwichMatches),
            norwichVersusCityScoredShare: share(norwichCityScored, norwichCityMatches),
            meanTopScorerGoals: Double(topScorerGoals) / seasonCount
        )
    }

    private static func recordLate(
        homeIndex: Int,
        awayIndex: Int,
        homeGoals: Int,
        awayGoals: Int,
        lateMatches: inout Int,
        lateScored: inout Int,
        lateEarlyMatches: inout Int,
        lateEarlyScored: inout Int
    ) {
        let pairs = [(homeIndex, homeGoals, awayIndex), (awayIndex, awayGoals, homeIndex)]
        for (index, goals, opponent) in pairs {
            guard index >= 15 else { continue }
            lateMatches += 1
            if goals > 0 { lateScored += 1 }
            if opponent < 6 {
                lateEarlyMatches += 1
                if goals > 0 { lateEarlyScored += 1 }
            }
        }
    }
}
