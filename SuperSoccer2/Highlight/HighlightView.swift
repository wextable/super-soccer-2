import ComposableArchitecture
import SwiftUI

struct HighlightView: View {
    @Bindable var store: StoreOf<HighlightFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var squashed = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            scoreboard
            ZStack(alignment: .bottom) {
                pitch
                ticker
                    .padding(theme.space.sm)
            }
            if store.reduceMotion && (store.phase == .incoming || store.phase == .shown) {
                Button {
                    store.send(.view(.advance))
                } label: {
                    Text(store.nextControlTitle)
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.phase == .fullTime {
                Button("Full-time stats") {
                    store.send(.view(.statsButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
                Button("Back to week") {
                    store.send(.view(.backButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            } else {
                Button("Skip") {
                    store.send(.view(.skipButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
        }
        .padding(theme.space.lg)
        .readingWidth()
        .themeScreen()
        .onAppear {
            store.send(.view(.onAppear(reduceMotion: reduceMotion)))
        }
        .animation(ballAnimation, value: store.ballProgress)
        .onChange(of: store.cameraFlip) { _, _ in
            guard !reduceMotion else { return }
            squashed = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                squashed = false
            }
        }
    }

    private var pitch: some View {
        PitchView(
            script: store.script,
            progress: store.ballProgress,
            attackingEnd: store.attackingEnd,
            attackingShirt: attackingKit.primary.color,
            attackingShorts: attackingKit.secondary.color,
            defendingShirt: defendingKit.primary.color,
            defendingShorts: defendingKit.secondary.color,
            minute: store.minuteText
        )
        .scaleEffect(y: squashed ? 0.08 : 1, anchor: .center)
        .rotation3DEffect(
            .degrees(squashed ? 75 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: squashed)
    }

    private var ballAnimation: Animation? {
        guard store.sentenceVisible, !reduceMotion else { return nil }
        return .easeInOut(duration: 1.7)
    }

    private var scoreboard: some View {
        HStack(alignment: .center, spacing: theme.space.sm) {
            ClubCrest(clubID: store.homeID)
            Text(store.homeShort)
                .font(theme.type.scoreSide)
            Text("\(store.homeScore)")
                .font(theme.type.scoreHero)
                .foregroundStyle(theme.colors.score.color)
                .contentTransition(.numericText())
            Text("–")
                .font(theme.type.scoreSide)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("\(store.awayScore)")
                .font(theme.type.scoreHero)
                .foregroundStyle(theme.colors.score.color)
                .contentTransition(.numericText())
            Text(store.awayShort)
                .font(theme.type.scoreSide)
            ClubCrest(clubID: store.awayID)
            Spacer()
            Text(store.minuteText)
                .font(theme.type.minute)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .foregroundStyle(theme.colors.text.color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreLabel)
    }

    private var scoreLabel: String {
        let score = "\(store.homeShort) \(store.homeScore), \(store.awayShort) \(store.awayScore)"
        switch store.phase {
        case .incoming:
            return "\(store.minute) minutes, \(score), before the shot"
        case .shown:
            return "\(store.minute) minutes, \(score)"
        case .halfTime:
            return "Half time, \(score)"
        case .fullTime:
            return "Full time, \(score)"
        }
    }

    private var ticker: some View {
        Text(store.sentenceVisible ? store.commentary : "…")
            .font(theme.type.ticker)
            .foregroundStyle(theme.colors.ticker.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.space.md)
            .background(theme.colors.tickerBackground.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.tickerRadius, style: .continuous))
            .accessibilityLabel(store.commentary)
            .accessibilityHidden(!store.sentenceVisible || store.phase == .fullTime)
    }

    private var attackingKit: Kit {
        store.attackingIsHome ? store.homeKit : store.awayKit
    }

    private var defendingKit: Kit {
        store.attackingIsHome ? store.awayKit : store.homeKit
    }
}
