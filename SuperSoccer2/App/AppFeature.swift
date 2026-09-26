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
        case matchweek(MatchweekFeature)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.selection, action: \.selection) {
            ClubSelectionFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case let .selection(.delegate(.clubPicked(id))):
                guard state.path.isEmpty,
                      let season = state.selection.season,
                      state.selection.clubs.contains(where: { $0.id == id })
                else { return .none }
                state.path.append(
                    .matchweek(MatchweekFeature.State(userClubID: id, season: season))
                )
                return .none

            case .selection, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
