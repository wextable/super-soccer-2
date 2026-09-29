import ComposableArchitecture
import Foundation
import Testing
@testable import SuperSoccer2

@Suite
@MainActor
struct PlayerDetailTests {
    @Test func theClubRosterPagesInListOrderAndStopsAtTheEnds() async {
        let starting = player("a", starter: true)
        let alsoStarting = player("b", starter: true)
        let bench = player("c", starter: false)
        let roster = [starting, alsoStarting, bench]
        let store = TestStore(
            initialState: PlayerDetailFeature.State(
                player: starting,
                clubName: "Manchester City",
                clubID: "manchester-city",
                showsExperience: true,
                roster: roster
            )
        ) {
            PlayerDetailFeature()
        }

        #expect(store.state.roleLine == "Starting")
        #expect(store.state.canShowPreviousPlayer == false)
        await store.send(.view(.previousPlayerTapped))
        await store.send(.view(.nextPlayerTapped)) {
            $0.player = alsoStarting
        }
        #expect(store.state.roleLine == "Starting")
        await store.send(.view(.nextPlayerTapped)) {
            $0.player = bench
        }
        #expect(store.state.roleLine == "On the bench")
        #expect(store.state.canShowNextPlayer == false)
        await store.send(.view(.nextPlayerTapped))
        await store.send(.view(.previousPlayerTapped)) {
            $0.player = alsoStarting
        }
    }

    @Test func aPlayerOpenedAloneStaysPut() async {
        let only = player("a", starter: true)
        let store = TestStore(
            initialState: PlayerDetailFeature.State(
                player: only,
                clubName: "Norwich City",
                clubID: "norwich-city"
            )
        ) {
            PlayerDetailFeature()
        }

        #expect(store.state.roleLine == nil)
        #expect(store.state.roster == nil)
        await store.send(.view(.previousPlayerTapped))
        await store.send(.view(.nextPlayerTapped))
        #expect(store.state.player == only)
    }
}

private func player(_ id: String, starter: Bool) -> Player {
    Player(
        id: id,
        firstName: "Bo",
        lastName: id,
        position: .forward,
        condition: 100,
        isStarter: starter,
        ratings: Ratings(
            speed: 70,
            shooting: 70,
            passing: 70,
            dribbling: 70,
            defending: 70,
            goalkeeping: 20
        )
    )
}
