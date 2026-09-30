import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var splash = SplashFeature.State()
        var frontDoor = FrontDoorFeature.State()
        /// The tab bar. It stays nil until a career is open, and then it is the root.
        var game: MatchweekFeature.State?
        /// The main menu, presented over the tabs.
        @Presents var menu: FrontDoorFeature.State?
        /// Team selection, presented over the front door or the menu. Dismissed when a club is taken.
        @Presents var selection: ClubSelectionFeature.State?
    }

    enum Action {
        case splash(SplashFeature.Action)
        case frontDoor(FrontDoorFeature.Action)
        case game(MatchweekFeature.Action)
        case menu(PresentationAction<FrontDoorFeature.Action>)
        case selection(PresentationAction<ClubSelectionFeature.Action>)
    }

    @Dependency(\.careerStore) var careerStore

    var body: some ReducerOf<Self> {
        Scope(state: \.splash, action: \.splash) {
            SplashFeature()
        }
        Scope(state: \.frontDoor, action: \.frontDoor) {
            FrontDoorFeature()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .splash:
                return .none

            case .frontDoor(.delegate(.newGame)):
                guard state.game == nil, state.selection == nil else { return .none }
                state.selection = ClubSelectionFeature.State()
                return .none

            case let .frontDoor(.delegate(.continueCareer(career))):
                guard state.game == nil else { return .none }
                state.game = MatchweekFeature.State(career: career)
                state.selection = nil
                return .none

            case .frontDoor:
                return .none

            case .game(.delegate(.openMenu)):
                guard state.menu == nil else { return .none }
                state.menu = FrontDoorFeature.State(mode: .menu)
                return .none

            case .game:
                return .none

            case .menu(.presented(.delegate(.newGame))):
                guard state.selection == nil else { return .none }
                state.selection = ClubSelectionFeature.State()
                return .none

            case .menu(.presented(.delegate(.dismiss))):
                state.menu = nil
                state.selection = nil
                return .none

            case .menu(.dismiss):
                state.selection = nil
                return .none

            case .menu:
                return .none

            case let .selection(.presented(.delegate(.clubPicked(clubID)))):
                guard
                    let selection = state.selection,
                    let season = selection.season,
                    selection.clubs.contains(where: { $0.id == clubID })
                else { return .none }
                let week = MatchweekFeature.State(userClubID: clubID, season: season)
                state.game = week
                state.selection = nil
                state.menu = nil
                return save(week)

            case .selection:
                return .none
            }
        }
        .ifLet(\.game, action: \.game) {
            MatchweekFeature()
        }
        .ifLet(\.$menu, action: \.menu) {
            FrontDoorFeature()
        }
        .ifLet(\.$selection, action: \.selection) {
            ClubSelectionFeature()
        }
    }

    private func save(_ week: MatchweekFeature.State) -> Effect<Action> {
        let career = week.career
        return .run { [careerStore] _ in
            await careerStore.save(career)
        }
    }
}
