import ComposableArchitecture
import Testing
@testable import SuperSoccer2

@Suite
@MainActor
struct SplashFeatureTests {
    @Test func theCardIsUpAtLaunch() {
        #expect(SplashFeature.State().isPresented)
        #expect(SplashFeature.hold == .milliseconds(1500))
    }

    @Test func theCardLeavesAfterTheHold() async {
        let clock = TestClock()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.appeared))
        await clock.advance(by: .milliseconds(1499))
        await clock.advance(by: .milliseconds(1))
        await store.receive(\.internal.holdFinished) {
            $0.isPresented = false
        }
    }

    @Test func aTapDismissesBeforeTheHold() async {
        let clock = TestClock()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.view(.appeared))
        await clock.advance(by: .milliseconds(400))
        await store.send(.view(.tapped)) {
            $0.isPresented = false
        }
    }

    @Test func aSecondAppearanceDoesNotBringTheCardBack() async {
        let store = TestStore(initialState: SplashFeature.State(isPresented: false)) {
            SplashFeature()
        }

        await store.send(.view(.appeared))
        await store.send(.view(.tapped))
    }
}
