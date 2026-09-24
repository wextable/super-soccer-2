import SwiftUI
import UIKit

/// Seed palette, type, and spacing for the three screens in this slice.
/// A fuller theme comes before any screen past this one.
enum Theme {
    static let reading: CGFloat = 680
    static let control: CGFloat = 44

    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    static let canvas = dynamic(light: rgb(231, 239, 232), dark: rgb(14, 21, 17))
    static let surface = dynamic(light: rgb(247, 251, 246), dark: rgb(23, 33, 27))
    static let ink = dynamic(light: rgb(20, 32, 24), dark: rgb(231, 242, 234))
    static let inkMuted = dynamic(light: rgb(78, 92, 84), dark: rgb(168, 184, 174))
    static let accent = dynamic(light: rgb(11, 110, 138), dark: rgb(126, 231, 255))
    static let accentInk = dynamic(light: rgb(255, 255, 255), dark: rgb(7, 17, 12))
    static let line = dynamic(light: rgb(213, 224, 216), dark: rgb(42, 58, 48))
    static let shadow = Color.black.opacity(0.08)
    static let ticker = Color(red: 126 / 255, green: 231 / 255, blue: 255 / 255)
    static let tickerBackground = Color(red: 7 / 255, green: 17 / 255, blue: 12 / 255)
    static let pitch = Color(red: 27 / 255, green: 107 / 255, blue: 52 / 255)
    static let pitchLine = Color.white.opacity(0.85)

    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

extension KitColor {
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

extension View {
    func themeScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.canvas)
    }

    func themeCard() -> some View {
        padding(Theme.Space.md)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.shadow, radius: 2, y: 1)
    }

    func readingWidth() -> some View {
        frame(maxWidth: Theme.reading)
            .frame(maxWidth: .infinity)
    }
}
