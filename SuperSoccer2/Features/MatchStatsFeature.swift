import ComposableArchitecture
import Foundation

/// Shot list shown after the reel. A later halftime stop can pass an earlier slice of the same shots.
@Reducer
struct MatchStatsFeature {
    @ObservableState
    struct State: Equatable {
        var title: String
        var homeShort: String
        var awayShort: String
        var rows: [Row]

        struct Row: Equatable, Identifiable, Sendable {
            var id: Int
            var minute: Int
            var shooter: String
            var result: ShotResult
            var isPenalty: Bool
            var isHome: Bool
        }

        var homeGoals: Int {
            rows.filter { $0.isHome && $0.result == .goal }.count
        }

        var awayGoals: Int {
            rows.filter { !$0.isHome && $0.result == .goal }.count
        }

        init(shots: [Shot], title: String = "Full time", homeShort: String, awayShort: String) {
            self.title = title
            self.homeShort = homeShort
            self.awayShort = awayShort
            rows = shots.enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.minute != rhs.element.minute {
                        return lhs.element.minute < rhs.element.minute
                    }
                    return lhs.offset < rhs.offset
                }
                .enumerated()
                .map { index, pair in
                    let shot = pair.element
                    return Row(
                        id: index,
                        minute: shot.minute,
                        shooter: shot.shooter.fullName,
                        result: shot.result,
                        isPenalty: shot.type == .penalty,
                        isHome: shot.isHome
                    )
                }
        }
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case backButtonTapped
        }

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { _, action in
            switch action {
            case .view(.backButtonTapped):
                return .send(.delegate(.dismissed))
            case .delegate:
                return .none
            }
        }
    }
}
