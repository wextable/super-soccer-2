import CoreText
import Foundation
import SwiftUI

/// Silkscreen, an OFL bitmap face in the 8-pixel game tradition. The license is `Fonts/OFL.txt`.
enum PixelFont {
    static let family = "Silkscreen"
    static let regular = "Silkscreen-Regular"
    static let bold = "Silkscreen-Bold"

    static func register() {
        for name in [regular, bold] {
            let urls = [
                Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
                Bundle.main.url(forResource: name, withExtension: "ttf")
            ]
            for url in urls.compactMap(\.self) {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle, bold: Bool = false) -> Font {
        .custom(bold ? Self.bold : Self.regular, size: size, relativeTo: style)
    }
}
