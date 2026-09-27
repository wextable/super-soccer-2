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

    private var choices: some View {
        WeekCard {
            ForEach(Array(store.choices.enumerated()), id: \.element.id) { index, choice in
                statRow(choice, isLast: index == store.choices.count - 1)
            }
        }
    }

    private func statRow(_ choice: SkillChoice, isLast: Bool) -> some View {
        let projection = SkillProjection.make(
            current: store.player.ratings.value(for: choice.stat),
            boost: choice.points
        )
        return VStack(spacing: 0) {
            Button {
                store.send(.view(.statTapped(choice.stat)))
            } label: {
                HStack(spacing: theme.space.sm) {
                    Text(choice.stat.label)
                        .font(theme.type.playerName)
                        .foregroundStyle(theme.colors.text.color)
                    RatingBar(track: .growth(projection), mark: .growth)
                        .frame(maxWidth: .infinity)
                    Text(projection.reading)
                        .font(theme.type.playerOverall)
                        .foregroundStyle(theme.colors.text.color)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(!projection.available)
            .opacity(projection.available ? 1 : 0.4)
            .accessibilityLabel(choiceLabel(choice.stat, projection))
            if !isLast {
                WeekHairline()
            }
        }
    }

    private func choiceLabel(_ stat: PlayerStat, _ projection: SkillProjection) -> String {
        if projection.available {
            return "\(stat.label), \(projection.current) to \(projection.next), for \(store.player.fullName)"
        }
        return "\(stat.label), \(projection.current), cannot increase, for \(store.player.fullName)"
    }
}
