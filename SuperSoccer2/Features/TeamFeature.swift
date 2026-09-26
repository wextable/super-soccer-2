import ComposableArchitecture
import Foundation

/// The club screen. The Club tab and a table row both open this.
@Reducer
struct TeamFeature {
    @ObservableState
    struct State: Equatable {
        var club: Club
        var played: Int
        var points: Int
        var goalDifference: Int
        @Presents var player: PlayerDetailFeature.State?
    }

    enum Action {
        case view(View)
        case player(PresentationAction<PlayerDetailFeature.Action>)

        @CasePathable
        enum View {
            case playerTapped(Player.ID)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.playerTapped(id)):
                guard let player = state.club.starters.first(where: { $0.id == id }) else { return .none }
                state.player = PlayerDetailFeature.State(player: player, clubName: state.club.name)
                return .none
            case .player:
                return .none
            }
        }
        .ifLet(\.$player, action: \.player) {
            PlayerDetailFeature()
        }
    }
}
