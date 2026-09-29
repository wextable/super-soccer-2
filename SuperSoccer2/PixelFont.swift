import CoreText
import Foundation
import SwiftUI

/// Jersey 15, an OFL retro face with open counters. The license is `Fonts/OFL.txt`.
enum PixelFont {
    static let family = "Jersey 15"
    static let regular = "Jersey15-Regular"

    static func register() {
        let urls = [
            Bundle.main.url(forResource: regular, withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: regular, withExtension: "ttf")
        ]
        for url in urls.compactMap(\.self) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(regular, size: size, relativeTo: style)
    }
}
