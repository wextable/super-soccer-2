import ComposableArchitecture
import Foundation

/// One unspent skill. The week does not move on until this stat is chosen.
@Reducer
struct SkillChoiceFeature {
    @ObservableState
    struct State: Equatable {
        var offerID: String
        var player: Player
        var choices: [SkillChoice]
        var step: Int
        var stepCount: Int
        /// Why this screen is in the way, such as “Before the next week”.
        var contextLine: String
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case statTapped(PlayerStat)
        }

        @CasePathable
        enum Delegate {
            case chose(PlayerStat)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.statTapped(stat)):
                guard state.choices.contains(where: { $0.stat == stat }) else { return .none }
                return .send(.delegate(.chose(stat)))

            case .delegate:
                return .none
            }
        }
    }
}
