import ComposableArchitecture
import SwiftUI

struct FrontDoorView: View {
    @Bindable var store: StoreOf<FrontDoorFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                actions
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Super Soccer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.mode == .menu {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        store.send(.view(.dismissButtonTapped))
                    }
                    .accessibilityHint("Closes the menu and returns to the season")
                }
            }
        }
        .tint(theme.colors.action.color)
        .onAppear { store.send(.view(.onAppear)) }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: store.canContinue)
        .sensoryFeedback(.selection, trigger: store.newGameTaps)
        .sensoryFeedback(.impact(weight: .light), trigger: store.continueTaps)
        .sensoryFeedback(.error, trigger: store.openFailures)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text("Super Soccer")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text("The season")
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text(tagline)
                .font(theme.type.tagline)
                .foregroundStyle(store.failedToOpen ? theme.colors.danger.color : theme.colors.secondaryText.color)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var actions: some View {
        if !store.hasChecked {
            VStack(spacing: theme.space.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(theme.colors.action.color)
                Text("Looking for a saved career.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: theme.space.md) {
                if store.canContinue {
                    Button("Continue") {
                        store.send(.view(.continueButtonTapped))
                    }
                    .buttonStyle(ThemeActionButtonStyle())
                    .disabled(store.isOpening || store.mode == .menu)
                    .opacity(store.mode == .menu ? 0.45 : 1)
                    .accessibilityHint(
                        store.mode == .menu
                            ? "You are already in this career"
                            : "Opens the saved career on the club tab"
                    )
                    Button("New Game") {
                        store.send(.view(.newGameButtonTapped))
                    }
                    .buttonStyle(QuietDoorButtonStyle())
                    .accessibilityHint("Starts a career and replaces the saved one")
                } else {
                    Button("New Game") {
                        store.send(.view(.newGameButtonTapped))
                    }
                    .buttonStyle(ThemeActionButtonStyle())
                    .accessibilityHint("Starts a career and replaces the saved one")
                }
                if store.isOpening {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(theme.colors.action.color)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Opening the career")
                }
            }
        }
    }

    private var tagline: String {
        if store.failedToOpen {
            "That career could not be opened."
        } else if store.canContinue {
            "One career is saved on this phone."
        } else if store.hasChecked {
            "No career on this phone yet."
        } else {
            "One career. Pick it up, or start again."
        }
    }
}

private struct QuietDoorButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.type.button)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl)
            .foregroundStyle(theme.colors.action.color)
            .background(theme.colors.card.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.buttonRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: theme.metrics.buttonRadius, style: .continuous)
                    .strokeBorder(theme.colors.hairline.color, lineWidth: theme.metrics.hairline)
            }
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
