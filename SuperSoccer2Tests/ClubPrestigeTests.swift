import ComposableArchitecture
import Testing
@testable import SuperSoccer2

@Suite
struct ClubPrestigeTests {
    @Test func fiftyOverallIsOneStarAndTheStepsStayOnHalfStars() {
        #expect(Club.prestigeStars(overall: 0) == 1)
        #expect(Club.prestigeStars(overall: 50) == 1)
        #expect(Club.prestigeStars(overall: 65) == 1)
        #expect(Club.prestigeStars(overall: 66) == 1.5)
        #expect(Club.prestigeStars(overall: 68) == 1.5)
        #expect(Club.prestigeStars(overall: 69) == 2)
        #expect(Club.prestigeStars(overall: 71) == 2)
        #expect(Club.prestigeStars(overall: 72) == 2.5)
        #expect(Club.prestigeStars(overall: 73) == 2.5)
        #expect(Club.prestigeStars(overall: 74) == 3)
        #expect(Club.prestigeStars(overall: 75) == 3)
        #expect(Club.prestigeStars(overall: 76) == 3.5)
        #expect(Club.prestigeStars(overall: 78) == 3.5)
        #expect(Club.prestigeStars(overall: 79) == 4)
        #expect(Club.prestigeStars(overall: 81) == 4)
        #expect(Club.prestigeStars(overall: 82) == 4.5)
        #expect(Club.prestigeStars(overall: 84) == 4.5)
        #expect(Club.prestigeStars(overall: 85) == 5)
        #expect(Club.prestigeStars(overall: 99) == 5)
        #expect(Club.prestigeLabel(stars: 1) == "1 star")
        #expect(Club.prestigeLabel(stars: 4) == "4 stars")
        #expect(Club.prestigeLabel(stars: 4.5) == "4.5 stars")
    }

    @Test func aLeagueSpreadsAcrossTheStarScale() {
        for seed in [UInt64(1), 7, 42, 99, 2024] {
            let stars = Set(LeagueDraft.makeLeague(seed: seed).clubs.map(\.prestigeStars))
            #expect(stars.count >= 6)
            #expect(stars.allSatisfy { $0 >= 1 && $0 <= 5 && $0 * 2 == ($0 * 2).rounded() })
            #expect(stars.contains { $0 <= 1.5 })
            #expect(stars.contains { $0 >= 4.5 })
        }
    }

    @Test func seedFortyTwoOrdersTheClubsByStarsThenName() {
        let season = LeagueDraft.makeLeague(seed: 42)
        let ordered = season.clubs.sorted(by: Club.prestigeOrder)
        #expect(ordered.map(\.name) == [
            "Liverpool",
            "Manchester City",
            "Manchester United",
            "Chelsea",
            "West Ham",
            "Arsenal",
            "Aston Villa",
            "Crystal Palace",
            "Tottenham",
            "Brighton",
            "Leicester City",
            "Wolverhampton",
            "Brentford",
            "Burnley",
            "Norwich City",
            "Southampton",
            "Watford",
            "Everton",
            "Leeds United",
            "Newcastle United",
        ])
        #expect(ordered.map(\.prestigeStars) == [
            5, 5, 5,
            4.5, 4.5,
            4,
            3.5, 3.5, 3.5,
            2.5, 2.5, 2.5,
            2, 2, 2, 2, 2,
            1.5, 1.5, 1.5,
        ])
    }
}

@Suite
@MainActor
struct ClubSelectionListTests {
    @Test func thePickerOffersEveryClubHighestStarsFirst() async {
        let store = TestStore(initialState: ClubSelectionFeature.State()) {
            ClubSelectionFeature()
        } withDependencies: {
            $0.entropy.nextSeed = { 42 }
        }
        store.exhaustivity = .off

        await store.send(.view(.onAppear))
        #expect(store.state.clubs.count == 20)
        #expect(store.state.clubs.map(\.name).first == "Liverpool")
        #expect(store.state.clubs.map(\.name) == store.state.clubs.sorted(by: Club.prestigeOrder).map(\.name))
        #expect(Set(store.state.clubs.map(\.id)) == Set(store.state.season?.clubs.map(\.id) ?? []))
    }
}
