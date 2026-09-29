import ComposableArchitecture
import SwiftUI

struct InjuryNoticeView: View {
    let store: StoreOf<InjuryNoticeFeature>
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
                .accessibilityHint("Goes on to the next injury, or to the rest of the week")
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
            Text("Uh oh")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.fitnessRed.color)
            if store.stepCount > 1 {
                Text("\(store.step) of \(store.stepCount)")
                    .font(theme.type.eyebrow)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .contentTransition(.numericText())
            }
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
                if store.notice.cause.isEmpty == false {
                    Text(store.notice.cause)
                        .font(theme.type.tagline)
                        .foregroundStyle(theme.colors.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(store.notice.healLine)
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, theme.space.md)
        }
        .accessibilityElement(children: .combine)
    }
}
