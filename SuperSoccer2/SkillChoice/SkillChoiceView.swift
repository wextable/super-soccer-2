import ComposableArchitecture
import SwiftUI

struct SkillChoiceView: View {
    let store: StoreOf<SkillChoiceFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                ratings
                choices
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .interactiveDismissDisabled()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.offerID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(store.contextLine)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            if store.stepCount > 1 {
                Text("\(store.step) of \(store.stepCount)")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .contentTransition(.numericText())
            }
            Text(store.player.position.title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.player.fullName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text("Pick one stat")
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .accessibilityElement(children: .combine)
    }

    private var ratings: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Ratings")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(Array(PlayerStat.allCases.enumerated()), id: \.element) { index, stat in
                    ratingRow(stat, isLast: index == PlayerStat.allCases.count - 1)
                }
            }
        }
    }

    private func ratingRow(_ stat: PlayerStat, isLast: Bool) -> some View {
        let value = store.player.ratings.value(for: stat)
        return VStack(spacing: 0) {
            HStack {
                Text(stat.label)
                    .font(theme.type.playerName)
                    .foregroundStyle(theme.colors.text.color)
                Spacer()
                Text("\(value)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
            }
            .frame(minHeight: theme.metrics.minimumControl)
            if !isLast {
                WeekHairline()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.label) \(value)")
    }

    private var choices: some View {
        WeekCard {
            ForEach(Array(store.choices.enumerated()), id: \.element.id) { index, choice in
                Button {
                    store.send(.view(.statTapped(choice.stat)))
                } label: {
                    HStack {
                        Text(choice.stat.label)
                            .font(theme.type.playerName)
                        Spacer()
                        Text("+\(choice.points)")
                            .font(theme.type.playerOverall)
                    }
                    .foregroundStyle(theme.colors.text.color)
                    .frame(minHeight: theme.metrics.minimumControl)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(choice.stat.label), plus \(choice.points), for \(store.player.fullName)")
                if index < store.choices.count - 1 {
                    WeekHairline()
                }
            }
        }
    }
}
