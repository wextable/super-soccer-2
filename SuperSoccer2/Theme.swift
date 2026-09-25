import SwiftUI
import UIKit

/// One look. Light and dark both live here. Screens read the environment and do not choose colors.
struct Theme: Equatable, Sendable {
    var colors: Colors
    var type: TypeScale
    var space: Space
    var metrics: Metrics

    /// The only shipped look. Replace the value installed in `AppView` to swap a future theme.
    static let starbyte = Theme(
        colors: .starbyte,
        type: .starbyte,
        space: .starbyte,
        metrics: .starbyte
    )
}

extension Theme {
    struct Colors: Equatable, Sendable {
        var background: AppearanceColor
        var text: AppearanceColor
        var secondaryText: AppearanceColor
        var action: AppearanceColor
        var actionLabel: AppearanceColor
        var score: AppearanceColor
        var pitch: AppearanceColor
        var pitchLine: AppearanceColor
        var card: AppearanceColor
        var hairline: AppearanceColor
        var shadow: AppearanceColor
        /// Debug-only controls. Not the action cyan.
        var danger: AppearanceColor
        /// Commentary stays the bright cyan on a near-black strip in both appearances.
        var ticker: AppearanceColor
        var tickerBackground: AppearanceColor

        static let starbyte = Colors(
            background: AppearanceColor(light: .byte(231, 239, 232), dark: .byte(14, 21, 17)),
            text: AppearanceColor(light: .byte(20, 32, 24), dark: .byte(231, 242, 234)),
            secondaryText: AppearanceColor(light: .byte(78, 92, 84), dark: .byte(168, 184, 174)),
            action: AppearanceColor(light: .byte(11, 110, 138), dark: .byte(126, 231, 255)),
            actionLabel: AppearanceColor(light: .byte(255, 255, 255), dark: .byte(7, 17, 12)),
            score: AppearanceColor(light: .byte(122, 78, 0), dark: .byte(255, 208, 64)),
            pitch: AppearanceColor(light: .byte(27, 107, 52), dark: .byte(27, 107, 52)),
            pitchLine: AppearanceColor(light: .byte(255, 255, 255, 0.85), dark: .byte(255, 255, 255, 0.85)),
            card: AppearanceColor(light: .byte(247, 251, 246), dark: .byte(23, 33, 27)),
            hairline: AppearanceColor(light: .byte(213, 224, 216), dark: .byte(42, 58, 48)),
            shadow: AppearanceColor(light: .byte(0, 0, 0, 0.08), dark: .byte(0, 0, 0, 0.08)),
            danger: AppearanceColor(light: .byte(168, 36, 42), dark: .byte(255, 99, 99)),
            ticker: AppearanceColor(light: .byte(126, 231, 255), dark: .byte(126, 231, 255)),
            tickerBackground: AppearanceColor(light: .byte(7, 17, 12), dark: .byte(7, 17, 12))
        )
    }

    /// Text styles, not point sizes, so Dynamic Type still applies. Names and buttons stay the system font.
    struct TypeScale: Equatable, Sendable {
        var eyebrow: Font
        var display: Font
        var clubName: Font
        var tagline: Font
        var body: Font
        var playerName: Font
        var playerOverall: Font
        var button: Font
        var rating: Font
        var overall: Font
        var homeLine: Font
        var opponentName: Font
        var captionNumber: Font
        var score: Font
        var scoreHero: Font
        var scoreSide: Font
        var minute: Font
        var ticker: Font

        static let starbyte = TypeScale(
            eyebrow: .system(.caption, design: .default, weight: .semibold).smallCaps(),
            display: .system(.largeTitle, design: .rounded, weight: .black),
            clubName: .system(.title2, design: .rounded, weight: .bold),
            tagline: .system(.title3, design: .serif, weight: .regular),
            body: .system(.body, design: .default, weight: .regular),
            playerName: .system(.body, design: .default, weight: .semibold),
            playerOverall: .system(.body, design: .default, weight: .semibold).monospacedDigit(),
            button: .system(.body, design: .default, weight: .semibold),
            rating: .system(.subheadline, design: .default, weight: .regular).monospacedDigit(),
            overall: .system(.subheadline, design: .default, weight: .semibold).monospacedDigit(),
            homeLine: .system(.subheadline, design: .default, weight: .regular).monospacedDigit(),
            opponentName: .system(.title3, design: .default, weight: .semibold),
            captionNumber: .system(.caption, design: .default, weight: .regular).monospacedDigit(),
            score: .system(.title, design: .default, weight: .bold).monospacedDigit(),
            scoreHero: .system(.largeTitle, design: .default, weight: .black).monospacedDigit(),
            scoreSide: .system(.title3, design: .monospaced, weight: .bold),
            minute: .system(.title3, design: .monospaced, weight: .semibold),
            ticker: .system(.body, design: .monospaced, weight: .regular)
        )
    }

    struct Space: Equatable, Sendable {
        var xxs: CGFloat
        var xs: CGFloat
        var sm: CGFloat
        var md: CGFloat
        var lg: CGFloat
        var xl: CGFloat
        var xxl: CGFloat

        static let starbyte = Space(xxs: 4, xs: 8, sm: 12, md: 16, lg: 24, xl: 32, xxl: 48)
    }

    struct Metrics: Equatable, Sendable {
        var minimumControl: CGFloat
        var readingWidth: CGFloat
        var cardRadius: CGFloat
        var buttonRadius: CGFloat
        var tickerRadius: CGFloat
        var pitchRadius: CGFloat
        var accentBar: CGFloat
        var hairline: CGFloat
        var pitchLine: CGFloat
        var shadowRadius: CGFloat
        var shadowY: CGFloat
        var emptyMinHeight: CGFloat
        var ballMinimum: CGFloat

        static let starbyte = Metrics(
            minimumControl: 44,
            readingWidth: 680,
            cardRadius: 16,
            buttonRadius: 14,
            tickerRadius: 10,
            pitchRadius: 12,
            accentBar: 6,
            hairline: 1,
            pitchLine: 2,
            shadowRadius: 2,
            shadowY: 1,
            emptyMinHeight: 220,
            ballMinimum: 10
        )
    }
}

struct AppearanceColor: Equatable, Sendable {
    var light: RGB
    var dark: RGB

    var color: Color {
        let light = light
        let dark = dark
        return Color(uiColor: UIColor { traits in
            let channel = traits.userInterfaceStyle == .dark ? dark : light
            return channel.uiColor
        })
    }
}

struct RGB: Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func byte(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) -> RGB {
        RGB(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

extension EnvironmentValues {
    @Entry var theme: Theme = .starbyte
}

extension KitColor {
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

struct ThemeDangerButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.type.button)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl)
            .foregroundStyle(theme.colors.actionLabel.color)
            .background(theme.colors.danger.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.buttonRadius, style: .continuous))
    }
}

struct ThemeActionButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.type.button)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl)
            .foregroundStyle(theme.colors.actionLabel.color)
            .background(theme.colors.action.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.buttonRadius, style: .continuous))
    }
}

private struct ThemeScreenModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.colors.background.color)
    }
}

private struct ThemeCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(theme.space.md)
            .background(theme.colors.card.color)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
    }
}

private struct ReadingWidthModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: theme.metrics.readingWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func themeScreen() -> some View {
        modifier(ThemeScreenModifier())
    }

    func themeCard() -> some View {
        modifier(ThemeCardModifier())
    }

    func readingWidth() -> some View {
        modifier(ReadingWidthModifier())
    }
}
