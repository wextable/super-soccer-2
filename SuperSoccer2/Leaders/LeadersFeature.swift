import ComposableArchitecture
import Foundation

@Reducer
struct LeadersFeature {
    @ObservableState
    struct State: Equatable {
        var goals: [LeagueLeaders.Row]
        var assists: [LeagueLeaders.Row]
        var saves: [LeagueLeaders.Row]
        var userClubID: String
        var goalsExpanded = false
        var assistsExpanded = false
        var savesExpanded = false
        @Presents var player: PlayerDetailFeature.State?

        static let listLimit = 10

        var isEmpty: Bool {
            goals.isEmpty && assists.isEmpty && saves.isEmpty
        }

        var listedGoals: [LeagueLeaders.Row] { listed(goals, expanded: goalsExpanded) }
        var listedAssists: [LeagueLeaders.Row] { listed(assists, expanded: assistsExpanded) }
        var listedSaves: [LeagueLeaders.Row] { listed(saves, expanded: savesExpanded) }
        var goalsCanExpand: Bool { canExpand(goals, expanded: goalsExpanded) }
        var assistsCanExpand: Bool { canExpand(assists, expanded: assistsExpanded) }
        var savesCanExpand: Bool { canExpand(saves, expanded: savesExpanded) }

        private func listed(_ rows: [LeagueLeaders.Row], expanded: Bool) -> [LeagueLeaders.Row] {
            expanded ? rows : Array(rows.prefix(Self.listLimit))
        }

        private func canExpand(_ rows: [LeagueLeaders.Row], expanded: Bool) -> Bool {
            !expanded && rows.count > Self.listLimit
        }
    }

    enum Action {
        case view(View)
        case player(PresentationAction<PlayerDetailFeature.Action>)

        @CasePathable
        enum View {
            case playerTapped(Player.ID)
            case expandGoalsTapped
            case expandAssistsTapped
            case expandSavesTapped
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
                state.player = PlayerDetailFeature.State(player: row.player, clubName: row.clubName)
                return .none
            case .view(.expandGoalsTapped):
                state.goalsExpanded = true
                return .none
            case .view(.expandAssistsTapped):
                state.assistsExpanded = true
                return .none
            case .view(.expandSavesTapped):
                state.savesExpanded = true
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
