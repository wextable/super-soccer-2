import ComposableArchitecture
@testable import SuperSoccer2

/// The growth effect sends two actions. Waiting for the last one finishes the bar.
@MainActor
func settleSkillChoice(_ store: TestStoreOf<MatchweekFeature>) async {
    guard let phase = store.state.ceremony?.levelUp?.phase, phase != .grown else { return }
    await store.receive(\.ceremony.levelUp.presented.internal.grown)
}

/// Injuries, level-ups, and returns sit in front of the week. Tests that only care about the next week walk through them.
/// A level up stays up through its bar, then Continue opens the next notice or the week.
@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<MatchweekFeature>) async {
    await walkCeremony(
        read: { store.state.ceremony },
        send: { await store.send(.ceremony($0)) },
        skip: { await store.skipReceivedActions() },
        settleLevelUp: { await store.receive(\.ceremony.levelUp.presented.internal.grown) },
        prepare: { store.dependencies.continuousClock = ImmediateClock() }
    )
}

@MainActor
func finishPresentedWeekSteps(_ store: TestStoreOf<AppFeature>) async {
    await walkCeremony(
        read: { store.state.game?.ceremony },
        send: { await store.send(.game(.ceremony($0))) },
        skip: { await store.skipReceivedActions() },
        settleLevelUp: { await store.receive(\.game.ceremony.levelUp.presented.internal.grown) },
        prepare: { store.dependencies.continuousClock = ImmediateClock() }
    )
}

@MainActor
private func walkCeremony(
    read: () -> WeekCeremonyFeature.State?,
    send: (WeekCeremonyFeature.Action) async -> Void,
    skip: () async -> Void,
    settleLevelUp: () async -> Void,
    prepare: () -> Void
) async {
    prepare()
    for _ in 0..<96 {
        guard let ceremony = read(), ceremony.notices.indices.contains(ceremony.index) else { break }
        switch ceremony.notices[ceremony.index] {
        case .injury:
            await send(.injury(.presented(.view(.continueTapped))))
            await skip()
        case .returnNotice:
            await send(.returnNotice(.presented(.view(.continueTapped))))
            await skip()
        case .levelUp:
            guard let choice = ceremony.levelUp else { return }
            switch choice.phase {
            case .choosing:
                let stat = choice.choices.first {
                    choice.player.ratings.value(for: $0.stat) < choice.player.potential.value(for: $0.stat)
                }?.stat ?? choice.choices[0].stat
                await send(.levelUp(.presented(.view(.statTapped(stat, reduceMotion: false)))))
                await skip()
            case .selected, .growing:
                await settleLevelUp()
            case .grown:
                await send(.levelUp(.presented(.view(.continueTapped))))
                await skip()
            }
        }
    }
}
