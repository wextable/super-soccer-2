import ComposableArchitecture
import Foundation

@Reducer
struct PlayerDetailFeature {
    @ObservableState
    struct State: Equatable {
        var player: Player
        var clubName: String
        var canManage: Bool = false
        var bestFit: Player? = nil
        var alternatives: [Player] = []
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case bestFitTapped
            case alternativeTapped(Player.ID)
        }

        @CasePathable
        enum Delegate {
            case replace(Player.ID)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.bestFitTapped):
                guard let incoming = state.bestFit?.id else { return .none }
                return .send(.delegate(.replace(incoming)))

            case let .view(.alternativeTapped(id)):
                guard state.alternatives.contains(where: { $0.id == id }) else { return .none }
                return .send(.delegate(.replace(id)))

            case .delegate:
                return .none
            }
        }
    }
}
