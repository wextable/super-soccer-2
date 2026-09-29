import ComposableArchitecture
import SwiftUI

/// Original title card: a block trophy, a manager in sunglasses, two celebrating players, and ribbons.
/// It is an overlay, not a screen in the navigation stack.
/// The picture is the same raster the launch storyboard centers, so the first frame continues that screen.
struct SplashView: View {
    let store: StoreOf<SplashFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            store.send(.view(.tapped))
        } label: {
            ZStack {
                theme.colors.background.color
                Image("LaunchSplash")
                    .renderingMode(.original)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .clipped()
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .onAppear { store.send(.view(.appeared)) }
        .accessibilityLabel("Super Soccer")
        .accessibilityHint("Dismisses the title screen")
    }
}

/// iPhone 17 points. The launch image is this canvas, centered, so the first frame meets the launch screen.
enum SplashCanvas {
    static let width: CGFloat = 402
    static let height: CGFloat = 874
}

/// Source of `LaunchSplash`. Rendered at `SplashCanvas` with `showsGround` off; the launch color paints the field.
struct SplashArtwork: View {
    var showsGround = true
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            if showsGround {
                theme.colors.background.color
            }
            VStack(spacing: theme.space.lg) {
                ribbon("NEW SEASON")
                Text("SUPER\nSOCCER")
                    .font(theme.type.scoreHero)
                    .foregroundStyle(theme.colors.title.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                SplashScene()
                    .frame(maxWidth: 440)
                    .frame(height: 240)
                ribbon("KICK OFF")
                Text("Tap to continue")
                    .font(theme.type.captionNumber)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func ribbon(_ text: String) -> some View {
        Text(text)
            .font(theme.type.button)
            .foregroundStyle(theme.colors.actionLabel.color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, theme.space.md)
            .padding(.vertical, theme.space.xs)
            .background(theme.colors.title.color)
            .overlay {
                Rectangle()
                    .strokeBorder(theme.colors.text.color, lineWidth: 2)
            }
    }
}

/// Pixel figures. Trophy on the left, manager on the right, players along the bottom.
private struct SplashScene: View {
    @Environment(\.theme) private var theme

    var body: some View {
        let grid = SplashGrid.make()
        Canvas { context, size in
            let width = grid.width
            let height = grid.height
            let cell = floor(min(size.width / CGFloat(width), size.height / CGFloat(height)))
            guard cell >= 1 else { return }
            let originX = floor((size.width - cell * CGFloat(width)) / 2)
            let originY = floor((size.height - cell * CGFloat(height)) / 2)
            let key = palette
            for y in 0..<height {
                for x in 0..<width {
                    let symbol = grid.cells[y * width + x]
                    guard let color = key[symbol] else { continue }
                    let rect = CGRect(
                        x: originX + CGFloat(x) * cell,
                        y: originY + CGFloat(y) * cell,
                        width: cell,
                        height: cell
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var palette: [Character: Color] {
        [
            "C": theme.colors.title.color,
            "Y": theme.colors.score.color,
            "W": theme.colors.text.color,
            "K": .black,
            "P": theme.colors.keeper.color,
            "G": theme.colors.defender.color,
            "B": theme.colors.midfielder.color,
            "R": theme.colors.forward.color,
            "H": Color(red: 1, green: 0.81, blue: 0.64),
            "D": Color(red: 0.08, green: 0.1, blue: 0.12),
            "F": theme.colors.pitch.color
        ]
    }
}

private struct SplashGrid {
    var width: Int
    var height: Int
    var cells: [Character]

    static func make() -> SplashGrid {
        var grid = SplashGrid(width: 42, height: 28, cells: Array(repeating: ".", count: 42 * 28))
        grid.stamp(trophy, x: 2, y: 1)
        grid.stamp(ball, x: 5, y: 12)
        grid.stamp(manager, x: 28, y: 1)
        grid.stamp(pinkPlayer, x: 8, y: 16)
        grid.stamp(greenPlayer, x: 22, y: 16)
        grid.stamp(ground, x: 4, y: 26)
        for dot in confetti {
            grid.stamp([String(dot.symbol)], x: dot.x, y: dot.y)
        }
        return grid
    }

    mutating func stamp(_ sprite: [String], x x0: Int, y y0: Int) {
        for (y, row) in sprite.enumerated() {
            for (x, symbol) in row.enumerated() where symbol != "." {
                let xx = x0 + x
                let yy = y0 + y
                guard xx >= 0, yy >= 0, xx < width, yy < height else { continue }
                cells[yy * width + xx] = symbol
            }
        }
    }

    private static let trophy = [
        "..CCCCCCCC..",
        ".CCYYYYYYCC.",
        "CCCYYYYYYCCC",
        "C.CYYYYYYC.C",
        "..CYYYYYYC..",
        "...CYYYYC...",
        "....CYYC....",
        "....CYYC....",
        "...CCCCCC...",
        "..CCCCCCCC.."
    ]

    private static let ball = [
        ".WWW.",
        "WWKWW",
        "WKKKW",
        "WWKWW",
        ".WWW."
    ]

    private static let manager = [
        "...KKKKKK...",
        "..KHHHHHHK..",
        "..KHCCCCCK..",
        "..KHHHHHHK..",
        "...KKKKKK...",
        ".....KK.....",
        "...DDDDDD...",
        "..DDCDDDDD..",
        "..DDDDDDDD..",
        "...DDDDDD...",
        ".....DDDD...",
        ".....D..D...",
        ".....D..D..."
    ]

    private static let pinkPlayer = [
        "H......H",
        "HH....HH",
        ".HHPPHH.",
        "..HPPH..",
        "..HPPH..",
        "..HKKH..",
        "...KK...",
        "..K..K..",
        "..K..K.."
    ]

    private static let greenPlayer = [
        "H......H",
        "HH....HH",
        ".HHGGHH.",
        "..HGGH..",
        "..HGGH..",
        "..HKKH..",
        "...KK...",
        "..K..K..",
        "..K..K.."
    ]

    private static let ground = [
        "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    ]

    private static let confetti: [(symbol: Character, x: Int, y: Int)] = [
        ("R", 16, 2),
        ("B", 18, 5),
        ("Y", 20, 1),
        ("P", 15, 8),
        ("C", 26, 6),
        ("W", 24, 3),
        ("R", 21, 14),
        ("B", 17, 12)
    ]
}
