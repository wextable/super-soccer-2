import ComposableArchitecture
import SwiftUI

struct SkillChoiceView: View {
    let store: StoreOf<SkillChoiceFeature>
    var walkHeader: String
    var step: Int
    var stepCount: Int
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                choices
                if store.phase == .grown {
                    Button("Continue") {
                        store.send(.view(.continueTapped))
                    }
                    .buttonStyle(ThemeActionButtonStyle())
                    .accessibilityHint("Goes on to the next level up, or to the rest of the week")
                }
            }
            .padding(theme.space.lg)
            .readingWidth()
            .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: store.phase == .grown)
        }
        .themeScreen()
        .interactiveDismissDisabled()
        .onAppear { store.send(.view(.onAppear)) }
        .sensoryFeedback(.selection, trigger: store.selectedStat)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            CeremonyFrame(header: walkHeader, step: step, stepCount: stepCount)
            Text("Level up")
                .font(theme.type.display)
                .foregroundStyle(theme.colors.title.color)
            Text(store.reason)
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.text.color)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.player.position.title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.color(for: store.player.position))
            Text("Level \(store.displayedLevel)")
                .font(theme.type.homeLine)
                .foregroundStyle(theme.colors.text.color)
                .accessibilityLabel("Level \(store.displayedLevel)")
            HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
                Text(store.player.fullName)
                    .font(theme.type.display)
                    .foregroundStyle(theme.colors.title.color)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: theme.space.sm)
                Text("\(store.displayedOverall)")
                    .font(theme.type.score)
                    .foregroundStyle(theme.colors.text.color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.displayedOverall)
                    .accessibilityLabel("Overall \(store.displayedOverall)")
            }
            Text(store.instruction)
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .accessibilityElement(children: .combine)
        .pixelHeader()
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
            boost: choice.points,
            ceiling: store.player.potential.value(for: choice.stat)
        )
        let isSelected = store.selectedStat == choice.stat && store.phase != .choosing
        let settled = isSelected && (store.phase == .growing || store.phase == .grown)
        let reading = settled && store.phase == .grown ? "\(projection.next)" : projection.reading
        return VStack(spacing: 0) {
            Button {
                store.send(.view(.statTapped(choice.stat, reduceMotion: reduceMotion)))
            } label: {
                HStack(spacing: theme.space.sm) {
                    RatingLabel(text: choice.stat.label)
                    RatingBar(
                        track: displayTrack(projection, settled: settled),
                        mark: .growth,
                        pulsesMark: store.phase == .choosing && projection.next > projection.current
                    )
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: SkillChoiceFeature.growSeconds),
                        value: settled
                    )
                    GrowthReading(reading: reading)
                }
                .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl, alignment: .leading)
                .padding(.horizontal, theme.space.xs)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: theme.metrics.pixelChrome ? 0 : 6, style: .continuous)
                            .fill(theme.colors.score.color.opacity(0.24))
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isSelected)
            }
            .buttonStyle(.plain)
            .disabled(store.phase != .choosing || !projection.available)
            .opacity(rowOpacity(available: projection.available, selected: isSelected))
            .accessibilityLabel(choiceLabel(choice.stat, projection))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            if !isLast {
                WeekHairline()
            }
        }
    }

    private func displayTrack(_ projection: SkillProjection, settled: Bool) -> RatingTrack {
        guard settled else { return .growth(projection) }
        return .growth(
            SkillProjection(
                current: projection.next,
                next: projection.next,
                ceiling: projection.ceiling,
                available: false
            )
        )
    }

    private func rowOpacity(available: Bool, selected: Bool) -> Double {
        if selected || (available && store.phase == .choosing) { return 1 }
        return 0.4
    }

    private func choiceLabel(_ stat: PlayerStat, _ projection: SkillProjection) -> String {
        let name = store.player.fullName
        if store.selectedStat == stat, store.phase == .grown {
            return "\(stat.label), \(projection.next), for \(name)"
        }
        if store.selectedStat == stat, store.phase != .choosing {
            return "\(stat.label), selected, \(projection.current) to \(projection.next), for \(name)"
        }
        if projection.available {
            return "\(stat.label), \(projection.current) to \(projection.next), for \(name)"
        }
        return "\(stat.label), \(projection.current), cannot increase, for \(name)"
    }
}
