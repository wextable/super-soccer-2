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
                    showsPasser: store.showsPasser,
                    result: store.result
                )
                ticker
                    .padding(theme.space.sm)
            }
            Button {
                store.send(.view(.backButtonTapped))
            } label: {
                Text("Back to the squad")
            }
            .buttonStyle(ThemeActionButtonStyle())
        }
        .padding(theme.space.lg)
        .readingWidth()
        .themeScreen()
        .onAppear {
            store.send(.view(.onAppear(reduceMotion: reduceMotion)))
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: store.ballProgress)
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
            Text("\(store.minute)'")
                .font(theme.type.minute)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .foregroundStyle(theme.colors.text.color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Full time \(store.homeShort) \(store.homeScore), \(store.awayShort) \(store.awayScore), minute \(store.minute)")
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
    }

    private var attackingColor: Color {
        (store.attackingIsHome ? store.homeKit : store.awayKit).primary.color
    }

    private var defendingColor: Color {
        (store.attackingIsHome ? store.awayKit : store.homeKit).primary.color
    }
}
