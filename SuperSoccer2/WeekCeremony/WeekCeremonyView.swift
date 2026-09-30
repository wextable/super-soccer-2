import ComposableArchitecture
import SwiftUI

/// The walk's header, its count, and the rule under them. The notice underneath stays its own screen.
struct CeremonyFrame: View {
    @Environment(\.theme) private var theme
    var header: String
    var step: Int
    var stepCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(header)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            StepCountRule(step: step, stepCount: stepCount)
        }
    }
}

/// Presents the ceremony's sheets from the matchweek without the tabs owning each notice.
struct WeekCeremonyHost: View {
    @Bindable var week: StoreOf<MatchweekFeature>

    var body: some View {
        if let store = week.scope(state: \.ceremony, action: \.ceremony) {
            Sheets(store: store)
        }
    }
}

private struct Sheets: View {
    @Bindable var store: StoreOf<WeekCeremonyFeature>

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .sheet(
                item: $store.scope(state: \.injury, action: \.injury)
            ) { noticeStore in
                InjuryNoticeView(
                    store: noticeStore,
                    walkHeader: store.header,
                    step: store.step,
                    stepCount: store.stepCount
                )
            }
            .sheet(
                item: $store.scope(state: \.returnNotice, action: \.returnNotice)
            ) { noticeStore in
                ReturnNoticeView(
                    store: noticeStore,
                    walkHeader: store.header,
                    step: store.step,
                    stepCount: store.stepCount
                )
            }
            .fullScreenCover(
                item: $store.scope(state: \.levelUp, action: \.levelUp)
            ) { skillStore in
                SkillChoiceView(
                    store: skillStore,
                    walkHeader: store.header,
                    step: store.step,
                    stepCount: store.stepCount
                )
            }
    }
}
