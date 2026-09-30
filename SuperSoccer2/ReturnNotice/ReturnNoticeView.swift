import ComposableArchitecture
import SwiftUI

struct ReturnNoticeView: View {
    let store: StoreOf<ReturnNoticeFeature>
    var walkHeader: String
    var step: Int
    var stepCount: Int
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
            CeremonyFrame(header: walkHeader, step: step, stepCount: stepCount)
            Text("Recovery")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.fitnessGreen.color)
            Text(store.notice.positionTitle)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.color(labeled: store.notice.positionTitle))
            Text(store.notice.playerName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.title.color)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .accessibilityElement(children: .combine)
        .pixelHeader()
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
