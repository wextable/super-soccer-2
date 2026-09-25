import ComposableArchitecture
import Foundation

@Reducer
struct ChampionshipFeature {
    @ObservableState
    struct State: Equatable {
        var record: SeasonRecord
        var nickname: String
        var kit: Kit
        var goals: [LeagueLeaders.Row]
        var assists: [LeagueLeaders.Row]
        var saves: [LeagueLeaders.Row]
        @Presents var player: PlayerDetailFeature.State?

        var championName: String { record.championName }
    }

    enum Action {
        case view(View)
        case player(PresentationAction<PlayerDetailFeature.Action>)

        @CasePathable
        enum View {
            case awardTapped(AwardKind)
            case leaderTapped(Player.ID)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.awardTapped(kind)):
                guard let award = state.record.awards.first(where: { $0.kind == kind }) else { return .none }
                state.player = PlayerDetailFeature.State(player: award.player)
                return .none
            case let .view(.leaderTapped(id)):
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
