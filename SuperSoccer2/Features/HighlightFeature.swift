import ComposableArchitecture
import Foundation

@Reducer
struct HighlightFeature {
    static let beatDuration: Duration = .milliseconds(800)

    @ObservableState
    struct State: Equatable {
        var homeShort: String
        var awayShort: String
        var homeScore: Int
        var awayScore: Int
        var minute: Int
        var commentary: String
        var showsPasser: Bool
        var attackingIsHome: Bool
        var homeKit: Kit
        var awayKit: Kit
        var result: ShotResult
        var ballProgress: Double
        var sentenceVisible: Bool

        init(match: MatchResult, home: Club, away: Club) {
            let shot = match.highlight
            homeShort = home.shortName
            awayShort = away.shortName
            homeScore = match.homeScore
            awayScore = match.awayScore
            minute = shot.minute
            commentary = match.commentary
            showsPasser = shot.passer != nil
            attackingIsHome = shot.isHome
            homeKit = home.kit
            awayKit = away.kit
            result = shot.result
            ballProgress = 0
            sentenceVisible = false
        }
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case onAppear(reduceMotion: Bool)
            case advance
            case backButtonTapped
        }

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    enum CancelID { case beat }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.onAppear(reduceMotion)):
                guard !state.sentenceVisible else { return .none }
                if reduceMotion {
                    state.ballProgress = 1
                    state.sentenceVisible = true
                    return .none
                }
                return .run { send in
                    do {
                        try await clock.sleep(for: HighlightFeature.beatDuration)
                        await send(.view(.advance))
                    } catch is CancellationError {
                        return
                    }
                }
                .cancellable(id: CancelID.beat)

            case .view(.advance):
                state.ballProgress = 1
                state.sentenceVisible = true
                return .none

            case .view(.backButtonTapped):
                return .merge(
                    .cancel(id: CancelID.beat),
                    .send(.delegate(.dismissed))
                )

            case .delegate:
                return .none
            }
        }
    }
}
