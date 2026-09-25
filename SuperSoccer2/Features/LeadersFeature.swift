import ComposableArchitecture
import Foundation

@Reducer
struct LeadersFeature {
    @ObservableState
    struct State: Equatable {
        var goals: [LeagueLeaders.Row]
        var assists: [LeagueLeaders.Row]
        var saves: [LeagueLeaders.Row]
        @Presents var player: PlayerDetailFeature.State?

        var isEmpty: Bool {
            goals.isEmpty && assists.isEmpty && saves.isEmpty
        }
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
                let row = state.goals.first { $0.player.id == id }
                    ?? state.assists.first { $0.player.id == id }
                    ?? state.saves.first { $0.player.id == id }
                guard let row else { return .none }
                state.player = PlayerDetailFeature.State(player: row.player)
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
