import ComposableArchitecture
import Foundation

@Reducer
struct ClubSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var clubs: [Club] = []
        var squadSeed: UInt64?
        var lastPickedID: String?
        var didFailToLoad = false
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        enum View {
            case onAppear
            case clubTapped(String)
        }

        enum Delegate {
            case clubPicked(String)
        }
    }

    @Dependency(\.entropy) var entropy

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                guard state.clubs.isEmpty else { return .none }
                let seed = entropy.nextSeed()
                let clubs = SquadCatalog.makePair(seed: seed)
                guard clubs.count == 2, clubs.allSatisfy({ $0.starters.count == 11 }) else {
                    state.didFailToLoad = true
                    return .none
                }
                state.squadSeed = seed
                state.clubs = clubs
                state.didFailToLoad = false
                return .none

            case let .view(.clubTapped(id)):
                guard state.clubs.contains(where: { $0.id == id }) else { return .none }
                state.lastPickedID = id
                return .send(.delegate(.clubPicked(id)))

            case .delegate:
                return .none
            }
        }
    }
}
