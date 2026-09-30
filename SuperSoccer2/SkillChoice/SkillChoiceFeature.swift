import ComposableArchitecture
import Foundation

/// One unspent skill. The row animates, then the screen stays until it is dismissed.
@Reducer
struct SkillChoiceFeature {
    /// The row is marked, then the bar has this long to grow. The overall updates when the grow ends.
    static let selectBeat = Duration.milliseconds(280)
    static let growBeat = Duration.milliseconds(520)

    static var growSeconds: Double {
        let parts = growBeat.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1_000_000_000_000_000_000
    }

    @ObservableState
    struct State: Equatable {
        var offerID: String
        var player: Player
        var choices: [SkillChoice]
        var selectedStat: PlayerStat? = nil
        var phase: Phase = .choosing

        enum Phase: Equatable, Sendable {
            case choosing
            case selected
            case growing
            case grown
        }

        var reason: String {
            LevelUpCopy.sentence(name: player.fullName, offerID: offerID)
        }

        /// “Pick one stat” until the bar has finished. Then the old game's line.
        var instruction: String {
            guard phase == .grown, let selectedStat else { return "Pick one stat" }
            return "His \(selectedStat.label) has really improved."
        }

        /// The number beside the name. It moves when the bar finishes, not when the row is tapped.
        var displayedOverall: Int {
            guard phase == .grown, let selectedStat else { return player.overall }
            return overall(after: selectedStat)
        }

        func overall(after stat: PlayerStat) -> Int {
            var next = player
            let boost = choices.first { $0.stat == stat }?.points ?? 0
            let projection = SkillProjection.make(
                current: player.ratings.value(for: stat),
                boost: boost,
                ceiling: player.potential.value(for: stat)
            )
            next.ratings.set(stat, to: projection.next)
            return next.overall
        }
    }

    enum Action {
        case view(View)
        case `internal`(Internal)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case statTapped(PlayerStat, reduceMotion: Bool)
            case continueTapped
        }

        @CasePathable
        enum Internal {
            case grow
            case grown
        }

        @CasePathable
        enum Delegate {
            case chose(PlayerStat)
        }
    }

    enum CancelID { case reveal }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.levelUpSound) var levelUpSound

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.statTapped(stat, reduceMotion)):
                guard state.phase == .choosing,
                      let choice = state.choices.first(where: { $0.stat == stat })
                else { return .none }
                let projection = SkillProjection.make(
                    current: state.player.ratings.value(for: stat),
                    boost: choice.points,
                    ceiling: state.player.potential.value(for: stat)
                )
                guard projection.available else { return .none }
                state.selectedStat = stat
                if reduceMotion {
                    state.phase = .grown
                    return playSound()
                }
                state.phase = .selected
                return reveal()

            case .view(.continueTapped):
                guard state.phase == .grown, let stat = state.selectedStat else { return .none }
                return .send(.delegate(.chose(stat)))

            case .internal(.grow):
                guard state.phase == .selected else { return .none }
                state.phase = .growing
                return playSound()

            case .internal(.grown):
                guard state.phase == .growing else { return .none }
                state.phase = .grown
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func reveal() -> Effect<Action> {
        .run { [clock] send in
            do {
                try await clock.sleep(for: Self.selectBeat)
                await send(.internal(.grow))
                try await clock.sleep(for: Self.growBeat)
                await send(.internal(.grown))
            } catch is CancellationError {
                return
            }
        }
        .cancellable(id: CancelID.reveal, cancelInFlight: true)
    }

    private func playSound() -> Effect<Action> {
        .run { [levelUpSound] _ in
            await levelUpSound.play()
        }
    }
}
