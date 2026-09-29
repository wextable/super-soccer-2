import ComposableArchitecture
import SwiftUI

/// Title card. An overlay, not a screen in the navigation stack.
/// The picture is the same asset the launch screen centers, at the same point size, on the same green.
struct SplashView: View {
    let store: StoreOf<SplashFeature>

    var body: some View {
        Button {
            store.send(.view(.tapped))
        } label: {
            ZStack {
                Color("LaunchGround")
                Image("LaunchSplash")
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: SplashCanvas.width, height: SplashCanvas.height)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onAppear { store.send(.view(.appeared)) }
        .accessibilityLabel("Super Soccer")
        .accessibilityHint("Dismisses the title screen")
    }
}

/// Point size of `LaunchSplash`. The system launch screen centers the asset at this size and does not scale it.
enum SplashCanvas {
    static let width: CGFloat = 402
    static let height: CGFloat = 600
}
