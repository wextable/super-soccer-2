import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct DevelopmentTests {
    @Test func kickoffRatingsStayAndPotentialSitsAboveThem() {
        let season = LeagueDraft.makeLeague(seed: 42)
        let again = LeagueDraft.makeLeague(seed: 42)
        let city = season.clubs[0]
        #expect(city.attack == 92)
        #expect(city.defense == 79)
        #expect(season.clubs[19].attack == 71)
        #expect(season.clubs[19].defense == 68)
        #expect(city.players.map(\.ratings) == again.clubs[0].players.map(\.ratings))
        #expect(city.players.map(\.age) == again.clubs[0].players.map(\.age))
        #expect(city.players.map(\.potential) == again.clubs[0].players.map(\.potential))
        #expect(city.players.map(\.growth) == again.clubs[0].players.map(\.growth))
        #expect(city.players.map(\.level) == again.clubs[0].players.map(\.level))
        #expect(city.players.allSatisfy { $0.skillsEarned == $0.level })

        let tuning = WeekTuning.current
        #expect(tuning.roomRange(for: tuning.youngestAge).lowerBound > tuning.roomRange(for: tuning.oldestAge).upperBound)
        #expect(tuning.highFastWeight > tuning.modestFastWeight)
        #expect(tuning.highSlowWeight > 0)
        #expect(tuning.modestFastWeight > 0)
        #expect(tuning.olderRoomMin == 0)
    }

    @Test func youngerPlayersHaveMoreRoomAndGrowthIsASeparateRoll() {
        let tuning = WeekTuning.current
        var youngRooms: [Int] = []
        var olderRooms: [Int] = []
        var olderCount = 0
        var olderAtCeiling = 0
        var highCount = 0
        var highFast = 0
        var highSlow = 0
        var modestCount = 0
        var modestFast = 0
        var modestSlow = 0
        var sawYoung = false
        var sawOlder = false

        for seed in [UInt64(1), 2, 7, 42, 99, 20240924] {
            let season = LeagueDraft.makeLeague(seed: seed)
            for player in season.clubs.flatMap(\.players) {
                #expect((tuning.youngestAge...tuning.oldestAge).contains(player.age))
                if player.age < tuning.primeAge { sawYoung = true }
                if player.age >= tuning.olderAge { sawOlder = true }
                var rooms: [Int] = []
                for stat in PlayerStat.allCases {
                    let rating = player.ratings.value(for: stat)
                    let ceiling = player.potential.value(for: stat)
                    #expect(ceiling >= rating)
                    #expect((1...99).contains(ceiling))
                    rooms.append(ceiling - rating)
                }
                let mean = rooms.reduce(0, +) / rooms.count
                if player.age < tuning.primeAge {
                    youngRooms.append(mean)
                }
                if player.age >= tuning.olderAge {
                    olderRooms.append(mean)
                    olderCount += 1
                    if rooms.contains(0) { olderAtCeiling += 1 }
                }
                if player.potential.highest >= tuning.highCeiling {
                    highCount += 1
                    if player.growth == .fast { highFast += 1 }
                    if player.growth == .slow { highSlow += 1 }
                } else {
                    modestCount += 1
                    if player.growth == .fast { modestFast += 1 }
                    if player.growth == .slow { modestSlow += 1 }
                }
            }
        }

        #expect(sawYoung)
        #expect(sawOlder)
        let youngMean = Double(youngRooms.reduce(0, +)) / Double(youngRooms.count)
        let olderMean = Double(olderRooms.reduce(0, +)) / Double(olderRooms.count)
        #expect(youngMean > olderMean + 4)
        #expect(olderAtCeiling > olderCount / 5)
        #expect(highCount > 0)
        #expect(modestCount > 0)
        #expect(highSlow > 0)
        #expect(modestFast > 0)
        #expect(modestSlow > 0)
        let highFastShare = Double(highFast) / Double(highCount)
        let modestFastShare = Double(modestFast) / Double(modestCount)
        #expect(highFastShare > modestFastShare + 0.15)
    }

    @Test func startingLevelStaysLowWhenYoungAndFarAndHighWhenOlderAndClose() {
        var tuning = WeekTuning.current
        tuning.startingLevelSpread = 0
        let far = potential(70)
        let youngFar = tuning.startingLevel(
            age: tuning.youngestAge,
            ratings: ratings(40),
            potential: far,
            playerID: "young-far"
        )
        let youngNear = tuning.startingLevel(
            age: tuning.youngestAge,
            ratings: ratings(64),
            potential: potential(70),
            playerID: "young-near"
        )
        let olderClose = tuning.startingLevel(
            age: tuning.olderAge,
            ratings: ratings(75),
            potential: potential(80),
            playerID: "older-close"
        )
        let olderNear = tuning.startingLevel(
            age: tuning.oldestAge,
            ratings: ratings(80),
            potential: potential(80),
            playerID: "older-near"
        )
        #expect(youngFar == 0)
        #expect(youngNear == 4)
        #expect(olderClose == 7)
        #expect(olderNear == tuning.startingLevelCap)
        #expect(youngFar < youngNear)
        #expect(youngNear < olderClose)
        #expect(olderClose < olderNear)

        let progress = tuning.openingProgress(
            age: tuning.oldestAge,
            ratings: ratings(80),
            potential: potential(80),
            playerID: "older-near"
        )
        #expect(progress.level == olderNear)
        #expect(progress.skillsEarned == progress.level)
        #expect(progress.xp == tuning.leftoverXP(level: progress.level, playerID: "older-near"))
        #expect(progress.xp < tuning.requiredXP(level: progress.level))
        #expect(tuning.requiredXP(level: 0) == 100)
        #expect(tuning.requiredXP(level: 4) == 140)
        #expect(tuning.xpForStart == 10)
        #expect(tuning.extraXpPerSkill == 10)
        let slot = tuning.openingXP(for: "older-near")
        #expect(tuning.leftoverXP(level: 0, playerID: "older-near") == slot)
        let scaled = tuning.leftoverXP(level: 4, playerID: "older-near")
        #expect(scaled == min(slot * 140 / 100, 139))
        #expect(scaled < 140)
    }

    @Test func generatedPlayersSpreadAcrossLevelsWithoutMovingRatings() {
        let tuning = WeekTuning.current
        var youngLevels: [Int] = []
        var olderLevels: [Int] = []
        var sawLow = false
        var sawHigh = false

        for seed in [UInt64(1), 2, 7, 42, 99] {
            let season = LeagueDraft.makeLeague(seed: seed)
            let again = LeagueDraft.makeLeague(seed: seed)
            #expect(season.clubs[0].players.map(\.ratings) == again.clubs[0].players.map(\.ratings))
            for player in season.clubs.flatMap(\.players) {
                #expect(player.skillsEarned == player.level)
                #expect(player.xp >= 0)
                #expect(player.xp < tuning.requiredXP(level: player.level))
                #expect(tuning.requiredXP(level: player.level) == tuning.xpForFirstSkill + tuning.extraXpPerSkill * player.level)
                if player.level <= 1 { sawLow = true }
                if player.level >= 8 { sawHigh = true }
                if player.age < tuning.primeAge { youngLevels.append(player.level) }
                if player.age >= tuning.olderAge { olderLevels.append(player.level) }
            }
        }

        #expect(sawLow)
        #expect(sawHigh)
        #expect(youngLevels.isEmpty == false)
        #expect(olderLevels.isEmpty == false)
        let youngMean = Double(youngLevels.reduce(0, +)) / Double(youngLevels.count)
        let olderMean = Double(olderLevels.reduce(0, +)) / Double(olderLevels.count)
        #expect(olderMean > youngMean + 3)
        #expect(Set(youngLevels + olderLevels).count >= 5)
    }
}

private func ratings(_ value: Int) -> Ratings {
    Ratings(
        speed: value,
        shooting: value,
        passing: value,
        dribbling: value,
        defending: value,
        goalkeeping: value
    )
}

private func potential(_ value: Int) -> Potential {
    Potential(
        speed: value,
        shooting: value,
        passing: value,
        dribbling: value,
        defending: value,
        goalkeeping: value
    )
}
