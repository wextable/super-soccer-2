import ComposableArchitecture
import Foundation

@Reducer
struct PlayerDetailFeature {
    @ObservableState
    struct State: Equatable {
        var player: Player
        var clubName: String
        var clubID: String = ""
        /// Experience is the user’s own squad. Another club’s player leaves it off.
        var showsExperience: Bool = false
    }

    enum Action {}

    var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
