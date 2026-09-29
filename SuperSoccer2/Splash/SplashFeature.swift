import ComposableArchitecture
import Foundation

/// Title card on launch. It sits over the root and is not a navigation destination.
@Reducer
struct SplashFeature {
    /// About a second and a half, then the card leaves on its own.
    static let hold = Duration.milliseconds(1500)

    @ObservableState
    struct State: Equatable {
        var isPresented = true
    }

    enum Action {
        case view(View)
        case `internal`(Internal)

        @CasePathable
        enum View {
            case appeared
            case tapped
        }

        @CasePathable
        enum Internal {
            case holdFinished
        }
    }

    enum CancelID { case hold }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.appeared):
                guard state.isPresented else { return .none }
                return .run { send in
                    do {
                        try await clock.sleep(for: Self.hold)
                        await send(.internal(.holdFinished))
                    } catch is CancellationError {
                        return
                    }
                }
                .cancellable(id: CancelID.hold, cancelInFlight: true)

            case .view(.tapped), .internal(.holdFinished):
                guard state.isPresented else { return .none }
                state.isPresented = false
                return .cancel(id: CancelID.hold)
            }
        }
    }
}
