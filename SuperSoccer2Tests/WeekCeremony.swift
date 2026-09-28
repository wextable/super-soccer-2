import ComposableArchitecture
@testable import SuperSoccer2

/// Injuries and skill picks sit in front of the week moving on. Tests that only care about the next week walk through them.
@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<MatchweekFeature>) async {
    for _ in 0..<48 {
        if store.state.injuryNotice != nil {
            await store.send(.injuryNotice(.presented(.view(.continueTapped))))
            await store.skipReceivedActions()
            continue
        }
        if store.state.returnNotice != nil {
            await store.send(.returnNotice(.presented(.view(.continueTapped))))
            await store.skipReceivedActions()
            continue
        }
        if let choice = store.state.skillChoice {
            let stat = choice.choices.first { choice.player.ratings.value(for: $0.stat) < choice.player.potential.value(for: $0.stat) }?.stat
                ?? choice.choices[0].stat
            await store.send(.skillChoice(.presented(.view(.statTapped(stat)))))
            await store.skipReceivedActions()
            continue
        }
        break
    }
}

@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<AppFeature>) async {
    for _ in 0..<48 {
        if store.state.game?.injuryNotice != nil {
            await store.send(.game(.injuryNotice(.presented(.view(.continueTapped)))))
            await store.skipReceivedActions()
            continue
        }
        if store.state.game?.returnNotice != nil {
            await store.send(.game(.returnNotice(.presented(.view(.continueTapped)))))
            await store.skipReceivedActions()
            continue
        }
        if let choice = store.state.game?.skillChoice {
            let stat = choice.choices.first { choice.player.ratings.value(for: $0.stat) < choice.player.potential.value(for: $0.stat) }?.stat
                ?? choice.choices[0].stat
            await store.send(.game(.skillChoice(.presented(.view(.statTapped(stat))))))
            await store.skipReceivedActions()
            continue
        }
        break
    }
}
