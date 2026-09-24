import ComposableArchitecture
import Foundation

@Reducer
struct MatchdayFeature {
    @ObservableState
    struct State: Equatable {
        var userClub: Club
        var opponent: Club
        var result: MatchResult?
        @Presents var highlight: HighlightFeature.State?
    }

    enum Action {
        case view(View)
        case highlight(PresentationAction<HighlightFeature.Action>)

        enum View {
            case kickOffButtonTapped
        }
    }

    @Dependency(\.entropy) var entropy

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.kickOffButtonTapped):
                if state.result == nil {
                    let seed = entropy.nextSeed()
                    state.result = MatchSimulator.simulate(
                        home: state.userClub,
                        away: state.opponent,
                        seed: seed
                    )
                }
                if let result = state.result {
                    state.highlight = HighlightFeature.State(
                        match: result,
                        home: state.userClub,
                        away: state.opponent
                    )
                }
                return .none

            case .highlight(.presented(.delegate(.dismissed))):
                state.highlight = nil
                return .none

            case .highlight:
                return .none
            }
        }
        .ifLet(\.$highlight, action: \.highlight) {
            HighlightFeature()
        }
    }
}
