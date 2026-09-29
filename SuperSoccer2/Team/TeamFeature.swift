import ComposableArchitecture
import Foundation

/// The club screen. The Club tab and a table row both open this.
@Reducer
struct TeamFeature {
    @ObservableState
    struct State: Equatable {
        var club: Club
        var won: Int
        var lost: Int
        var drawn: Int
        var points: Int
        var goalDifference: Int
        /// Table place once this club has played. Hidden before that.
        var place: Int? = nil
        /// The user’s own club can change the lineup. Another club’s row cannot.
        var canManage: Bool = false
        @Presents var substitution: SubstitutionFeature.State?
        @Presents var player: PlayerDetailFeature.State?
    }

    enum Action {
        case view(View)
        case substitution(PresentationAction<SubstitutionFeature.Action>)
        case player(PresentationAction<PlayerDetailFeature.Action>)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case playerTapped(Player.ID)
            case restStarter(Player.ID)
            case playBench(Player.ID)
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
                state.player = PlayerDetailFeature.State(
                    player: player,
                    clubName: state.club.name,
                    clubID: state.club.id,
                    showsExperience: state.canManage,
                    roster: state.canManage ? state.club.listedPlayers : nil
                )
                return .none

            case let .view(.restStarter(id)):
                return present(.rest, playerID: id, in: &state)

            case let .view(.playBench(id)):
                return present(.play, playerID: id, in: &state)

            case let .substitution(.presented(.delegate(.chosen(id)))):
                guard let swap = state.substitution?.swap(chosenID: id) else {
                    state.substitution = nil
                    return .none
                }
                state.substitution = nil
                return .send(.delegate(.replace(outgoing: swap.outgoing, incoming: swap.incoming)))

            case .substitution(.presented(.delegate(.cancelled))), .substitution(.dismiss):
                state.substitution = nil
                return .none

            case .substitution, .player, .delegate:
                return .none
            }
        }
        .ifLet(\.$substitution, action: \.substitution) {
            SubstitutionFeature()
        }
        .ifLet(\.$player, action: \.player) {
            PlayerDetailFeature()
        }
    }

    private func present(
        _ kind: SubstitutionFeature.State.Kind,
        playerID: Player.ID,
        in state: inout State
    ) -> Effect<Action> {
        guard state.canManage, state.substitution == nil,
              let player = state.club.players.first(where: { $0.id == playerID }),
              let prompt = SubstitutionFeature.State.make(kind, player: player, in: state.club.players)
        else { return .none }
        state.substitution = prompt
        return .none
    }
}
