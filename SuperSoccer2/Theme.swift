import SwiftUI
import UIKit

/// Looks the screens can wear. `AppView` installs one. Screens read the environment and do not choose colors.
struct Theme: Equatable, Sendable {
    var colors: Colors
    var type: TypeScale
    var space: Space
    var metrics: Metrics

    /// Light and dark, the look this theme replaced at launch.
    static let `default` = Theme(
        colors: .default,
        type: .default,
        space: .default,
        metrics: .default
    )

    /// Black and dark green grounds, hard edges, cyan titles, chunky pixel type.
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
        var fitnessGreen: AppearanceColor
        var fitnessYellow: AppearanceColor
        var fitnessOrange: AppearanceColor
        var fitnessRed: AppearanceColor
        /// Commentary stays the bright cyan on a near-black strip in both appearances.
        var ticker: AppearanceColor
        var tickerBackground: AppearanceColor
        /// Screen titles. On the light look this matches `text`, so those titles stay put.
        var title: AppearanceColor
        /// Position ink, in this order: keeper pink, defender green, midfielder blue, forward red.
        var keeper: AppearanceColor
        var defender: AppearanceColor
        var midfielder: AppearanceColor
        var forward: AppearanceColor

        static let `default` = Colors(
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
            fitnessGreen: AppearanceColor(light: .byte(15, 110, 52), dark: .byte(102, 220, 140)),
            fitnessYellow: AppearanceColor(light: .byte(140, 84, 0), dark: .byte(255, 196, 72)),
            fitnessOrange: AppearanceColor(light: .byte(174, 68, 8), dark: .byte(255, 146, 48)),
            fitnessRed: AppearanceColor(light: .byte(168, 36, 42), dark: .byte(255, 120, 110)),
            ticker: AppearanceColor(light: .byte(126, 231, 255), dark: .byte(126, 231, 255)),
            tickerBackground: AppearanceColor(light: .byte(7, 17, 12), dark: .byte(7, 17, 12)),
            title: AppearanceColor(light: .byte(20, 32, 24), dark: .byte(231, 242, 234)),
            keeper: AppearanceColor(light: .byte(176, 24, 120), dark: .byte(255, 120, 196)),
            defender: AppearanceColor(light: .byte(16, 122, 48), dark: .byte(88, 214, 116)),
            midfielder: AppearanceColor(light: .byte(24, 78, 184), dark: .byte(112, 168, 255)),
            forward: AppearanceColor(light: .byte(176, 36, 28), dark: .byte(255, 84, 64))
        )

        static let starbyte = Colors(
            background: AppearanceColor(light: .byte(6, 24, 14), dark: .byte(0, 0, 0)),
            text: AppearanceColor(light: .byte(236, 244, 236), dark: .byte(236, 244, 236)),
            secondaryText: AppearanceColor(light: .byte(154, 184, 164), dark: .byte(154, 184, 164)),
            action: AppearanceColor(light: .byte(126, 231, 255), dark: .byte(126, 231, 255)),
            actionLabel: AppearanceColor(light: .byte(0, 0, 0), dark: .byte(0, 0, 0)),
            score: AppearanceColor(light: .byte(255, 208, 64), dark: .byte(255, 208, 64)),
            pitch: AppearanceColor(light: .byte(22, 120, 48), dark: .byte(22, 120, 48)),
            pitchLine: AppearanceColor(light: .byte(255, 255, 255), dark: .byte(255, 255, 255)),
            card: AppearanceColor(light: .byte(10, 36, 22), dark: .byte(8, 16, 12)),
            hairline: AppearanceColor(light: .byte(40, 90, 64), dark: .byte(40, 90, 64)),
            shadow: AppearanceColor(light: .byte(0, 0, 0), dark: .byte(0, 0, 0)),
            danger: AppearanceColor(light: .byte(255, 72, 64), dark: .byte(255, 72, 64)),
            fitnessGreen: AppearanceColor(light: .byte(80, 230, 110), dark: .byte(80, 230, 110)),
            fitnessYellow: AppearanceColor(light: .byte(255, 210, 64), dark: .byte(255, 210, 64)),
            fitnessOrange: AppearanceColor(light: .byte(255, 140, 40), dark: .byte(255, 140, 40)),
            fitnessRed: AppearanceColor(light: .byte(255, 80, 72), dark: .byte(255, 80, 72)),
            ticker: AppearanceColor(light: .byte(126, 231, 255), dark: .byte(126, 231, 255)),
            tickerBackground: AppearanceColor(light: .byte(0, 0, 0), dark: .byte(0, 0, 0)),
            title: AppearanceColor(light: .byte(126, 231, 255), dark: .byte(126, 231, 255)),
            keeper: AppearanceColor(light: .byte(255, 105, 190), dark: .byte(255, 105, 190)),
            defender: AppearanceColor(light: .byte(64, 220, 90), dark: .byte(64, 220, 90)),
            midfielder: AppearanceColor(light: .byte(80, 150, 255), dark: .byte(80, 150, 255)),
            forward: AppearanceColor(light: .byte(255, 72, 48), dark: .byte(255, 72, 48))
        )

        func color(for position: Position) -> Color {
            switch position {
            case .keeper: keeper.color
            case .defender: defender.color
            case .midfielder: midfielder.color
            case .forward: forward.color
            }
        }

        func color(labeled name: String) -> Color {
            if let position = Position(labeled: name) {
                color(for: position)
            } else {
                title.color
            }
        }
    }

    /// Text styles, not point sizes, so Dynamic Type still applies.
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

        static let `default` = TypeScale(
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

        /// Body, lists, and buttons are phone-readable. Titles stay a step above that, not a poster.
        static let starbyte = TypeScale(
            eyebrow: PixelFont.font(15, relativeTo: .caption),
            display: PixelFont.font(24, relativeTo: .title),
            clubName: PixelFont.font(22, relativeTo: .title2),
            tagline: PixelFont.font(17, relativeTo: .title3),
            body: PixelFont.font(20, relativeTo: .body),
            playerName: PixelFont.font(20, relativeTo: .body),
            playerOverall: PixelFont.font(20, relativeTo: .body),
            button: PixelFont.font(20, relativeTo: .body),
            rating: PixelFont.font(17, relativeTo: .subheadline),
            overall: PixelFont.font(18, relativeTo: .subheadline),
            homeLine: PixelFont.font(17, relativeTo: .subheadline),
            opponentName: PixelFont.font(20, relativeTo: .title3),
            captionNumber: PixelFont.font(16, relativeTo: .caption),
            score: PixelFont.font(22, relativeTo: .title),
            scoreHero: PixelFont.font(26, relativeTo: .largeTitle),
            scoreSide: PixelFont.font(18, relativeTo: .title3),
            minute: PixelFont.font(18, relativeTo: .title3),
            ticker: PixelFont.font(17, relativeTo: .body)
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

        static let `default` = Space(xxs: 4, xs: 8, sm: 12, md: 16, lg: 24, xl: 32, xxl: 48)
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
        /// Crest beside a club name in a row.
        var crest: CGFloat
        /// Crest beside a club name in a title.
        var crestMark: CGFloat
        /// Hard pixel borders, rules, and bar chrome. The light look leaves this off.
        var pixelChrome: Bool

        static let `default` = Metrics(
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
            ballMinimum: 10,
            crest: 28,
            crestMark: 44,
            pixelChrome: false
        )

        static let starbyte = Metrics(
            minimumControl: 44,
            readingWidth: 680,
            cardRadius: 0,
            buttonRadius: 0,
            tickerRadius: 0,
            pitchRadius: 0,
            accentBar: 4,
            hairline: 2,
            pitchLine: 2,
            shadowRadius: 0,
            shadowY: 0,
            emptyMinHeight: 220,
            ballMinimum: 10,
            crest: 28,
            crestMark: 44,
            pixelChrome: true
        )
    }
}

struct AppearanceColor: Equatable, Sendable {
    var light: RGB
    var dark: RGB

    var color: Color {
        Color(uiColor: uiColor)
    }

    var uiColor: UIColor {
        let light = light
        let dark = dark
        return UIColor { traits in
            let channel = traits.userInterfaceStyle == .dark ? dark : light
            return channel.uiColor
        }
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

extension Theme.Colors {
    func fitness(_ band: FitnessBand) -> Color {
        switch band {
        case .green: fitnessGreen.color
        case .yellow: fitnessYellow.color
        case .orange: fitnessOrange.color
        case .red: fitnessRed.color
        }
    }
}

extension KitColor {
    var color: Color {
        Color(red: red, green: green, blue: blue)
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
            .overlay {
                if theme.metrics.pixelChrome {
                    Rectangle()
                        .strokeBorder(theme.colors.title.color, lineWidth: 2)
                }
            }
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

private struct PixelHeaderModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            content
            if theme.metrics.pixelChrome {
                PixelRule()
            }
        }
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

    func pixelHeader() -> some View {
        modifier(PixelHeaderModifier())
    }
}
