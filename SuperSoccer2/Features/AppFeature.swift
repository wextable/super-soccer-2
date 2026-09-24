import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var selection = ClubSelectionFeature.State()
        var path = StackState<Path.State>()
    }

    enum Action {
        case selection(ClubSelectionFeature.Action)
        case path(StackActionOf<Path>)
    }

    @Reducer(state: .equatable)
    enum Path {
        case matchday(MatchdayFeature)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.selection, action: \.selection) {
            ClubSelectionFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case let .selection(.delegate(.clubPicked(id))):
                guard state.path.isEmpty,
                      let user = state.selection.clubs.first(where: { $0.id == id }),
                      let opponent = state.selection.clubs.first(where: { $0.id != id })
                else { return .none }
                state.path.append(
                    .matchday(MatchdayFeature.State(userClub: user, opponent: opponent))
                )
                return .none

            case .selection, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
