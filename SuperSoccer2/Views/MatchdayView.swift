import ComposableArchitecture
import SwiftUI

struct MatchdayView: View {
    @Bindable var store: StoreOf<MatchdayFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                scoreBanner
                opponentCard
                squad
                kickOff
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle(store.userClub.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.colors.action.color)
        .fullScreenCover(
            item: $store.scope(state: \.highlight, action: \.highlight)
        ) { highlightStore in
            HighlightView(store: highlightStore)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.result?.seed)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text("Your eleven")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.userClub.name)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text("Home · \(store.userClub.summaryLine)")
                .font(theme.type.homeLine)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
    }

    @ViewBuilder
    private var scoreBanner: some View {
        if let result = store.result {
            HStack {
                VStack(alignment: .leading, spacing: theme.space.xxs) {
                    Text("Full time")
                        .font(theme.type.eyebrow)
                        .foregroundStyle(theme.colors.action.color)
                    Text("\(store.userClub.shortName) \(result.homeScore) – \(result.awayScore) \(store.opponent.shortName)")
                        .font(theme.type.score)
                        .foregroundStyle(theme.colors.score.color)
                        .contentTransition(.numericText())
                }
                Spacer()
            }
            .themeCard()
            .accessibilityLabel("Full time, \(store.userClub.name) \(result.homeScore), \(store.opponent.name) \(result.awayScore)")
        } else {
            Text("No score yet.")
                .font(theme.type.body)
                .foregroundStyle(theme.colors.secondaryText.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .themeCard()
        }
    }

    private var opponentCard: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(store.opponent.kit.primary.color)
                .frame(width: theme.metrics.accentBar)
            VStack(alignment: .leading, spacing: theme.space.xxs) {
                Text("Away")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text(store.opponent.name)
                    .font(theme.type.opponentName)
                    .foregroundStyle(theme.colors.text.color)
                Text(store.opponent.summaryLine)
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            .padding(theme.space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.card.color)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
        .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
    }

    private var squad: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Starters")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            VStack(spacing: 0) {
                ForEach(Array(store.userClub.starters.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: theme.space.sm) {
                        Text(player.position.label)
                            .font(theme.type.eyebrow)
                            .foregroundStyle(theme.colors.action.color)
                            .frame(width: theme.metrics.minimumControl, alignment: .leading)
                        Text(player.fullName)
                            .font(theme.type.playerName)
                            .foregroundStyle(theme.colors.text.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(player.overall)")
                            .font(theme.type.playerOverall)
                            .foregroundStyle(theme.colors.text.color)
                    }
                    .frame(minHeight: theme.metrics.minimumControl)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(player.fullName), \(player.position.label), overall \(player.overall)")
                    if index < store.userClub.starters.count - 1 {
                        Rectangle()
                            .fill(theme.colors.hairline.color)
                            .frame(height: theme.metrics.hairline)
                    }
                }
            }
            .padding(.horizontal, theme.space.md)
            .background(theme.colors.card.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        }
    }

    private var kickOff: some View {
        Button {
            store.send(.view(.kickOffButtonTapped))
        } label: {
            Text(store.result == nil ? "Kick off" : "Watch the beat")
        }
        .buttonStyle(ThemeActionButtonStyle())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.result == nil)
    }
}
