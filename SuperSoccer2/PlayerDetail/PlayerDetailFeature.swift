import ComposableArchitecture
import Foundation

@Reducer
struct PlayerDetailFeature {
    @ObservableState
    struct State: Equatable {
        var player: Player
        var clubName: String
        var clubID: String = ""
        /// Experience is the user’s own squad. Another club’s player leaves it off.
        var showsExperience: Bool = false
        /// Club-roster order when this screen was opened from the user’s club. Nil stays on one player.
        var roster: [Player]? = nil

        /// “Starting” or “On the bench” while paging the user’s club. Absent everywhere else.
        var roleLine: String? {
            guard roster != nil else { return nil }
            return player.isStarter ? "Starting" : "On the bench"
        }

        var rosterIndex: Int? {
            roster?.firstIndex { $0.id == player.id }
        }

        var canShowPreviousPlayer: Bool {
            guard let rosterIndex else { return false }
            return rosterIndex > 0
        }

        var canShowNextPlayer: Bool {
            guard let roster, let rosterIndex else { return false }
            return rosterIndex + 1 < roster.count
        }
    }

    enum Action {
        case view(View)

        @CasePathable
        enum View {
            case previousPlayerTapped
            case nextPlayerTapped
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.previousPlayerTapped):
                guard let roster = state.roster, let index = state.rosterIndex, index > 0 else { return .none }
                state.player = roster[index - 1]
                return .none

            case .view(.nextPlayerTapped):
                guard let roster = state.roster, let index = state.rosterIndex, index + 1 < roster.count else { return .none }
                state.player = roster[index + 1]
                return .none
            }
        }
    }
}
