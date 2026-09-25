import ComposableArchitecture
import SwiftUI

struct HighlightView: View {
    @Bindable var store: StoreOf<HighlightFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.md) {
            scoreboard
            ZStack(alignment: .bottom) {
                PitchView(
                    progress: store.ballProgress,
                    attacking: attackingColor,
                    defending: defendingColor,
                    showsPasser: store.showsPasser && store.phase != .fullTime,
                    result: store.result
                )
                ticker
                    .padding(theme.space.sm)
            }
            if store.reduceMotion, store.phase != .fullTime {
                Button {
                    store.send(.view(.advance))
                } label: {
                    Text(nextTitle)
                }
                .buttonStyle(ThemeActionButtonStyle())
            }
            if store.phase == .fullTime {
                Button("Full-time stats") {
                    store.send(.view(.statsButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
            } else {
                Button("Skip") {
                    store.send(.view(.skipButtonTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
                Button("Back to the squad") {
                    store.send(.view(.backButtonTapped))
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
    }

    private var ballAnimation: Animation? {
        guard store.sentenceVisible, !reduceMotion else { return nil }
        return .easeInOut(duration: 0.8)
    }

    private var nextTitle: String {
        if store.phase == .shown, store.index + 1 >= store.shots.count {
            return "Full time"
        }
        return "Next shot"
    }

    private var scoreboard: some View {
        HStack(alignment: .firstTextBaseline) {
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

    private var attackingColor: Color {
        (store.attackingIsHome ? store.homeKit : store.awayKit).primary.color
    }

    private var defendingColor: Color {
        (store.attackingIsHome ? store.awayKit : store.homeKit).primary.color
    }
}
