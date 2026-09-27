import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var frontDoor = FrontDoorFeature.State()
        var path = StackState<Path.State>()
    }

    enum Action {
        case frontDoor(FrontDoorFeature.Action)
        case path(StackActionOf<Path>)
    }

    @Reducer(state: .equatable)
    enum Path {
        case selection(ClubSelectionFeature)
        case matchweek(MatchweekFeature)
    }

    @Dependency(\.careerStore) var careerStore

    var body: some ReducerOf<Self> {
        Scope(state: \.frontDoor, action: \.frontDoor) {
            FrontDoorFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .frontDoor(.delegate(.newGame)):
                guard state.path.isEmpty else { return .none }
                state.path.append(.selection(ClubSelectionFeature.State()))
                return .none

            case let .frontDoor(.delegate(.continueCareer(career))):
                guard state.path.isEmpty else { return .none }
                state.path.append(.matchweek(MatchweekFeature.State(career: career)))
                return .none

            case .frontDoor:
                return .none

            case let .path(.element(id: id, action: .selection(.delegate(.clubPicked(clubID))))):
                guard
                    state.path.count == 1,
                    let selection = state.path[id: id, case: \.selection],
                    let season = selection.season,
                    selection.clubs.contains(where: { $0.id == clubID })
                else { return .none }
                let week = MatchweekFeature.State(userClubID: clubID, season: season)
                state.path.append(.matchweek(week))
                return save(week)

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private func save(_ week: MatchweekFeature.State) -> Effect<Action> {
        let career = Career(matchweek: week)
        return .run { [careerStore] _ in
            await careerStore.save(career)
        }
    }
}
