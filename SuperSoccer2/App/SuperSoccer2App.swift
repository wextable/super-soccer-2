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

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ClubSelectionView(store: store.scope(state: \.selection, action: \.selection))
        } destination: { store in
            switch store.case {
            case let .matchday(store):
                MatchdayView(store: store)
            }
        }
        .tint(Theme.accent)
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
