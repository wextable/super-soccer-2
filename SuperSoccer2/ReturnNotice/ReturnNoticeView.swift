import ComposableArchitecture
import SwiftUI

struct ReturnNoticeView: View {
    let store: StoreOf<ReturnNoticeFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                story
                Button("Continue") {
                    store.send(.view(.continueTapped))
                }
                .buttonStyle(ThemeActionButtonStyle())
                .accessibilityHint("Goes on to the next return, or back to the week")
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .interactiveDismissDisabled()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text("Recovery")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.fitnessGreen.color)
            if store.stepCount > 1 {
                Text("\(store.step) of \(store.stepCount)")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .contentTransition(.numericText())
            }
            Text(store.notice.positionTitle)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.notice.playerName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
        }
        .accessibilityElement(children: .combine)
    }

    private var story: some View {
        WeekCard {
            VStack(alignment: .leading, spacing: theme.space.sm) {
                Text(store.notice.headline)
                    .font(theme.type.playerName)
                    .foregroundStyle(theme.colors.text.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Fit to play.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, theme.space.md)
        }
        .accessibilityElement(children: .combine)
    }
}
