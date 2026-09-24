import ComposableArchitecture
import SwiftUI

struct MatchdayView: View {
    @Bindable var store: StoreOf<MatchdayFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                header
                scoreBanner
                opponentCard
                squad
                kickOff
            }
            .padding(Theme.Space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle(store.userClub.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.accent)
        .fullScreenCover(
            item: $store.scope(state: \.highlight, action: \.highlight)
        ) { highlightStore in
            HighlightView(store: highlightStore)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.result?.seed)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Your eleven")
                .font(.caption.weight(.semibold).smallCaps())
                .foregroundStyle(Theme.accent)
            Text(store.userClub.name)
                .font(.largeTitle.weight(.black))
                .fontDesign(.rounded)
                .foregroundStyle(Theme.ink)
            Text("Home · \(store.userClub.summaryLine)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.inkMuted)
        }
    }

    @ViewBuilder
    private var scoreBanner: some View {
        if let result = store.result {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text("Full time")
                        .font(.caption.weight(.semibold).smallCaps())
                        .foregroundStyle(Theme.accent)
                    Text("\(store.userClub.shortName) \(result.homeScore) – \(result.awayScore) \(store.opponent.shortName)")
                        .font(.title.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                }
                Spacer()
            }
            .themeCard()
            .accessibilityLabel("Full time, \(store.userClub.name) \(result.homeScore), \(store.opponent.name) \(result.awayScore)")
        } else {
            Text("No score yet.")
                .font(.body)
                .foregroundStyle(Theme.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .themeCard()
        }
    }

    private var opponentCard: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(store.opponent.kit.primary.color)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text("Away")
                    .font(.caption.weight(.semibold).smallCaps())
                    .foregroundStyle(Theme.inkMuted)
                Text(store.opponent.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(store.opponent.summaryLine)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.inkMuted)
            }
            .padding(Theme.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Theme.shadow, radius: 2, y: 1)
    }

    private var squad: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text("Starters")
                .font(.caption.weight(.semibold).smallCaps())
                .foregroundStyle(Theme.inkMuted)
            VStack(spacing: 0) {
                ForEach(Array(store.userClub.starters.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: Theme.Space.sm) {
                        Text(player.position.label)
                            .font(.caption.weight(.semibold).smallCaps())
                            .foregroundStyle(Theme.accent)
                            .frame(width: 44, alignment: .leading)
                        Text(player.fullName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(player.overall)")
                            .font(.body.monospacedDigit().weight(.bold))
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(minHeight: Theme.control)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(player.fullName), \(player.position.label), overall \(player.overall)")
                    if index < store.userClub.starters.count - 1 {
                        Rectangle()
                            .fill(Theme.line)
                            .frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.md)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.shadow, radius: 2, y: 1)
        }
    }

    private var kickOff: some View {
        Button {
            store.send(.view(.kickOffButtonTapped))
        } label: {
            Text(store.result == nil ? "Kick off" : "Watch the beat")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.control)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.accentInk)
        .background(Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.result == nil)
    }
}
