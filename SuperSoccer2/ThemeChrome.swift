import SwiftUI
import UIKit

extension Theme {
    /// Pixel navigation titles and tab labels. The light look keeps the system bars.
    @MainActor
    func installNavigationChrome() {
        guard metrics.pixelChrome else { return }
        let titleFont = UIFont(name: PixelFont.regular, size: 16) ?? .preferredFont(forTextStyle: .headline)
        let tabFont = UIFont(name: PixelFont.regular, size: 10) ?? titleFont
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = colors.background.uiColor
        nav.shadowColor = colors.title.uiColor
        nav.titleTextAttributes = [
            .foregroundColor: colors.title.uiColor,
            .font: titleFont
        ]
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        bar.tintColor = colors.title.uiColor

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = colors.background.uiColor
        let item = UITabBarItemAppearance()
        item.normal.titleTextAttributes = [
            .font: tabFont,
            .foregroundColor: colors.secondaryText.uiColor
        ]
        item.selected.titleTextAttributes = [
            .font: tabFont,
            .foregroundColor: colors.title.uiColor
        ]
        tab.stackedLayoutAppearance = item
        tab.inlineLayoutAppearance = item
        tab.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

struct ThemeDangerButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        ThemeButtonChrome(
            fill: theme.colors.danger.color,
            ink: theme.colors.actionLabel.color,
            pressed: configuration.isPressed
        ) {
            configuration.label
        }
    }
}

struct ThemeActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        ThemeButtonChrome(
            fill: theme.colors.action.color,
            ink: theme.colors.actionLabel.color,
            pressed: configuration.isPressed
        ) {
            configuration.label
        }
    }
}

struct ThemeButtonChrome<Label: View>: View {
    @Environment(\.theme) private var theme
    var fill: Color
    var ink: Color
    var pressed: Bool
    @ViewBuilder var label: () -> Label

    var body: some View {
        label()
            .font(theme.type.button)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl)
            .foregroundStyle(ink)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.buttonRadius, style: .continuous))
            .overlay {
                if theme.metrics.pixelChrome {
                    Rectangle()
                        .strokeBorder(theme.colors.text.color, lineWidth: 2)
                }
            }
            .opacity(theme.metrics.pixelChrome && pressed ? 0.82 : 1)
    }
}
