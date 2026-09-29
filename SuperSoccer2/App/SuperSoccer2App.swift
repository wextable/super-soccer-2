import ComposableArchitecture
import SwiftUI

@main
struct SuperSoccer2App: App {
    init() {
        PixelFont.register()
    }

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

    /// The look for every screen. `Theme.default` is the light and dark look.
    private let theme = Theme.starbyte

    var body: some View {
        root
            .tint(theme.colors.action.color)
            .environment(\.theme, theme)
            .overlay {
                if store.splash.isPresented {
                    SplashView(store: store.scope(state: \.splash, action: \.splash))
                }
            }
            .onAppear { theme.installNavigationChrome() }
    }

    /// No career yet: the front door is the first screen. A career makes the tab bar the root.
    /// Team selection and the menu are presented over that root, so neither can be popped back to.
    @ViewBuilder
    private var root: some View {
        if let gameStore = store.scope(state: \.game, action: \.game) {
            NavigationStack {
                MatchweekView(store: gameStore)
            }
            .sheet(item: $store.scope(state: \.menu, action: \.menu)) { menuStore in
                menu(menuStore)
            }
        } else {
            NavigationStack {
                FrontDoorView(store: store.scope(state: \.frontDoor, action: \.frontDoor))
            }
            .sheet(item: $store.scope(state: \.selection, action: \.selection)) { selectionStore in
                clubSelection(selectionStore)
            }
        }
    }

    private func menu(_ menuStore: StoreOf<FrontDoorFeature>) -> some View {
        NavigationStack {
            FrontDoorView(store: menuStore)
        }
        .sheet(item: $store.scope(state: \.selection, action: \.selection)) { selectionStore in
            clubSelection(selectionStore)
        }
        .environment(\.theme, theme)
    }

    private func clubSelection(_ selectionStore: StoreOf<ClubSelectionFeature>) -> some View {
        NavigationStack {
            ClubSelectionView(store: selectionStore)
        }
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
