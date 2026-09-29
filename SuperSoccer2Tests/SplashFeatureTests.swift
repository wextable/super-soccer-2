import ComposableArchitecture
import Testing
import UIKit
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

    @Test func theLaunchPictureSitsOnThePitchGreen() {
        let named = UIColor(named: "LaunchGround")
        #expect(named != nil)
        let pitch = RGB.byte(76, 131, 62)
        expect(named, matches: pitch, style: .light)
        expect(named, matches: pitch, style: .dark)

        let image = UIImage(named: "LaunchSplash")
        #expect(image != nil)
        #expect(image?.size == CGSize(width: SplashCanvas.width, height: SplashCanvas.height))
    }

    private func expect(_ color: UIColor?, matches channel: RGB, style: UIUserInterfaceStyle) {
        let resolved = color?.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let didRead = resolved?.getRed(&red, green: &green, blue: &blue, alpha: &alpha) ?? false
        #expect(didRead)
        #expect(abs(Double(red) - channel.red) < 0.004)
        #expect(abs(Double(green) - channel.green) < 0.004)
        #expect(abs(Double(blue) - channel.blue) < 0.004)
    }

    @Test func aSecondAppearanceDoesNotBringTheCardBack() async {
        let store = TestStore(initialState: SplashFeature.State(isPresented: false)) {
            SplashFeature()
        }

        await store.send(.view(.appeared))
        await store.send(.view(.tapped))
    }
}
