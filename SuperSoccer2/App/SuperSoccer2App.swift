import ComposableArchitecture
import SwiftUI

@main
struct SuperSoccer2App: App {
    var body: some Scene {
        WindowGroup {
            if !TestRuntime.isRunningTests {
                AppView(
                    store: Store(initialState: AppFeature.State()) {
                        AppFeature()
                    }
                )
            }
        }
    }
}

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    /// The look for every screen. A future theme replaces this value and nothing else.
    private let theme = Theme.starbyte

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ClubSelectionView(store: store.scope(state: \.selection, action: \.selection))
        } destination: { store in
            switch store.case {
            case let .matchday(store):
                MatchdayView(store: store)
            }
        }
        .tint(theme.colors.action.color)
        .environment(\.theme, theme)
    }
}

enum TestRuntime {
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }
}
