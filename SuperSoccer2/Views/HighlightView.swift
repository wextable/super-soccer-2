import ComposableArchitecture
import SwiftUI

struct HighlightView: View {
    @Bindable var store: StoreOf<HighlightFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
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
                    .padding(Theme.Space.sm)
            }
            Button {
                store.send(.view(.backButtonTapped))
            } label: {
                Text("Back to the squad")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.control)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.accentInk)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(Theme.Space.lg)
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
                .font(.title3.monospaced().weight(.bold))
            Text("\(store.homeScore)")
                .font(.largeTitle.monospacedDigit().weight(.black))
                .contentTransition(.numericText())
            Text("–")
                .font(.title2.monospaced())
                .foregroundStyle(Theme.inkMuted)
            Text("\(store.awayScore)")
                .font(.largeTitle.monospacedDigit().weight(.black))
                .contentTransition(.numericText())
            Text(store.awayShort)
                .font(.title3.monospaced().weight(.bold))
            Spacer()
            Text("\(store.minute)'")
                .font(.title3.monospaced().weight(.semibold))
                .foregroundStyle(Theme.inkMuted)
        }
        .foregroundStyle(Theme.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Full time \(store.homeShort) \(store.homeScore), \(store.awayShort) \(store.awayScore), minute \(store.minute)")
    }

    private var ticker: some View {
        Text(store.sentenceVisible ? store.commentary : "…")
            .font(.body.monospaced())
            .foregroundStyle(Theme.ticker)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Space.md)
            .background(Theme.tickerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityLabel(store.commentary)
    }

    private var attackingColor: Color {
        (store.attackingIsHome ? store.homeKit : store.awayKit).primary.color
    }

    private var defendingColor: Color {
        (store.attackingIsHome ? store.awayKit : store.homeKit).primary.color
    }
}
