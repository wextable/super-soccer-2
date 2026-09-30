import ComposableArchitecture
import Foundation

/// One return, read at the start of the week after it has advanced.
@Reducer
struct ReturnNoticeFeature {
    @ObservableState
    struct State: Equatable {
        var notice: ReturnNotice
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case continueTapped
        }

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { _, action in
            switch action {
            case .view(.continueTapped):
                return .send(.delegate(.dismissed))
            case .delegate:
                return .none
            }
        }
    }
}
