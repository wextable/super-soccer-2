import ComposableArchitecture
import Foundation

@Reducer
struct PlayerDetailFeature {
    @ObservableState
    struct State: Equatable {
        var player: Player
        var clubName: String
    }

    enum Action {
        case appeared
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { _, _ in .none }
    }
}
