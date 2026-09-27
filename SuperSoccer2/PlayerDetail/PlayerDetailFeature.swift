import ComposableArchitecture
import Foundation

@Reducer
struct PlayerDetailFeature {
    @ObservableState
    struct State: Equatable {
        var player: Player
        var clubName: String
        var clubID: String = ""
    }

    enum Action {}

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
