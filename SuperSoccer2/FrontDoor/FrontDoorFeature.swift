import ComposableArchitecture
import Foundation

@Reducer
struct FrontDoorFeature {
    @ObservableState
    struct State: Equatable {
        var canContinue = false
        var hasChecked = false
        var isOpening = false
        var failedToOpen = false
        var newGameTaps = 0
        var continueTaps = 0
        var openFailures = 0
    }

    enum Action {
        case view(View)
        case availabilityChecked(Bool)
        case careerLoaded(Career)
        case careerMissing
        case delegate(Delegate)

        @CasePathable
        enum View {
            case onAppear
            case newGameButtonTapped
            case continueButtonTapped
        }

        @CasePathable
        enum Delegate {
            case newGame
            case continueCareer(Career)
        }
    }

    @Dependency(\.careerStore) var careerStore

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .run { [careerStore] send in
                    let present = await careerStore.exists()
                    await send(.availabilityChecked(present))
                }

            case let .availabilityChecked(present):
                state.hasChecked = true
                state.canContinue = present
                if present {
                    state.failedToOpen = false
                }
                return .none

            case .view(.newGameButtonTapped):
                state.newGameTaps += 1
                return .send(.delegate(.newGame))

            case .view(.continueButtonTapped):
                guard state.canContinue, !state.isOpening else { return .none }
                state.continueTaps += 1
                state.isOpening = true
                state.failedToOpen = false
                return .run { [careerStore] send in
                    if let career = await careerStore.load() {
                        await send(.careerLoaded(career))
                    } else {
                        await send(.careerMissing)
                    }
                }

            case let .careerLoaded(career):
                state.isOpening = false
                return .send(.delegate(.continueCareer(career)))

            case .careerMissing:
                state.isOpening = false
                state.canContinue = false
                state.failedToOpen = true
                state.openFailures += 1
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
