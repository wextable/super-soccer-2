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
        /// The user’s own club can rest a starter. Another club’s row cannot.
        var canManage: Bool = false
        @Presents var player: PlayerDetailFeature.State?
    }

    enum Action {
        case view(View)
        case player(PresentationAction<PlayerDetailFeature.Action>)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case playerTapped(Player.ID)
            case restStarter(Player.ID)
        }

        @CasePathable
        enum Delegate {
            case replace(outgoing: Player.ID, incoming: Player.ID)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.playerTapped(id)):
                guard let player = state.club.players.first(where: { $0.id == id }) else { return .none }
                state.player = detail(for: player, in: state)
                return .none

            case let .view(.restStarter(id)):
                guard let starter = state.club.players.first(where: { $0.id == id }),
                      let incoming = WeekBetween.bestFit(replacing: starter, in: state.club.players)
                else { return .none }
                return .send(.delegate(.replace(outgoing: id, incoming: incoming.id)))

            case let .player(.presented(.delegate(.replace(incoming)))):
                guard let outgoing = state.player?.player.id else { return .none }
                return .send(.delegate(.replace(outgoing: outgoing, incoming: incoming)))

            case .player, .delegate:
                return .none
            }
        }
        .ifLet(\.$player, action: \.player) {
            PlayerDetailFeature()
        }
    }

    private func detail(for player: Player, in state: State) -> PlayerDetailFeature.State {
        let manages = state.canManage && player.isStarter && player.injury == nil
        return PlayerDetailFeature.State(
            player: player,
            clubName: state.club.name,
            canManage: manages,
            bestFit: manages ? WeekBetween.bestFit(replacing: player, in: state.club.players) : nil,
            alternatives: manages ? WeekBetween.alternatives(replacing: player, in: state.club.players) : []
        )
    }
}
