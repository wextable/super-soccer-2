import ComposableArchitecture
import Foundation

/// One injury, read after the match and before the week moves on.
@Reducer
struct InjuryNoticeFeature {
    @ObservableState
    struct State: Equatable {
        var notice: InjuryNotice
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
