import ComposableArchitecture
@testable import SuperSoccer2

/// The growth effect sends two actions. Waiting for the last one finishes the bar.
@MainActor
func settleSkillChoice(_ store: TestStoreOf<MatchweekFeature>) async {
    guard store.state.skillChoice?.phase != .grown else { return }
    await store.receive(\.skillChoice.presented.internal.grown)
}

/// Injuries and skill picks sit in front of the week moving on. Tests that only care about the next week walk through them.
/// A level up stays up through its bar, then Continue opens the next one or the week.
@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<MatchweekFeature>) async {
    store.dependencies.continuousClock = ImmediateClock()
    for _ in 0..<96 {
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
            switch choice.phase {
            case .choosing:
                let stat = choice.choices.first { choice.player.ratings.value(for: $0.stat) < choice.player.potential.value(for: $0.stat) }?.stat
                    ?? choice.choices[0].stat
                await store.send(.skillChoice(.presented(.view(.statTapped(stat, reduceMotion: false)))))
                await store.skipReceivedActions()
            case .selected, .growing:
                await store.receive(\.skillChoice.presented.internal.grown)
            case .grown:
                await store.send(.skillChoice(.presented(.view(.continueTapped))))
                await store.skipReceivedActions()
            }
            continue
        }
        break
    }
}

@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<AppFeature>) async {
    store.dependencies.continuousClock = ImmediateClock()
    for _ in 0..<96 {
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
            switch choice.phase {
            case .choosing:
                let stat = choice.choices.first { choice.player.ratings.value(for: $0.stat) < choice.player.potential.value(for: $0.stat) }?.stat
                    ?? choice.choices[0].stat
                await store.send(.game(.skillChoice(.presented(.view(.statTapped(stat, reduceMotion: false))))))
                await store.skipReceivedActions()
            case .selected, .growing:
                await store.receive(\.game.skillChoice.presented.internal.grown)
            case .grown:
                await store.send(.game(.skillChoice(.presented(.view(.continueTapped)))))
                await store.skipReceivedActions()
            }
            continue
        }
        break
    }
}
