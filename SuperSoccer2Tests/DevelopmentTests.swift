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
}
