import Testing
@testable import SuperSoccer2

@Suite
struct ThemeTests {
    @Test func defaultKeepsLightAndDarkOnEachRole() {
        let colors = Theme.default.colors
        #expect(colors.background.light != colors.background.dark)
        #expect(colors.text.light != colors.text.dark)
        #expect(colors.secondaryText.light != colors.secondaryText.dark)
        #expect(colors.action.light != colors.action.dark)
        #expect(colors.score.light != colors.score.dark)
        #expect(colors.card.light != colors.card.dark)
        #expect(colors.pitch.light == colors.pitch.dark)
        #expect(colors.score.light != colors.text.light)
        #expect(colors.action.dark == colors.ticker.dark)
        #expect(colors.danger.light != colors.danger.dark)
        #expect(colors.danger.light != colors.action.light)
        #expect(colors.fitnessGreen.light != colors.fitnessGreen.dark)
        #expect(colors.fitnessYellow.light != colors.fitnessYellow.dark)
        #expect(colors.fitnessOrange.light != colors.fitnessOrange.dark)
        #expect(colors.fitnessRed.light != colors.fitnessRed.dark)
        #expect(colors.fitnessGreen.light != colors.fitnessYellow.light)
        #expect(colors.fitnessYellow.light != colors.fitnessOrange.light)
        #expect(colors.fitnessOrange.light != colors.fitnessRed.light)
        #expect(colors.fitnessYellow.dark != colors.fitnessOrange.dark)
        #expect(colors.fitnessOrange.dark != colors.fitnessRed.dark)
        #expect(colors.title == colors.text)
        #expect(Theme.default.metrics.pixelChrome == false)
        #expect(Theme.default.metrics.minimumControl == 44)
        #expect(Theme.default.metrics.cardRadius == 16)
        #expect(Theme.default.metrics.crest > 0)
        #expect(Theme.default.metrics.crestMark >= Theme.default.metrics.crest)
        expectPositionInks(colors)
    }

    @Test func starbyteIsDarkHardAndCyan() {
        let colors = Theme.starbyte.colors
        #expect(colors.background.light.red < 0.1)
        #expect(colors.background.light.green < 0.2)
        #expect(colors.background.light.blue < 0.1)
        #expect(colors.background.dark.red == 0)
        #expect(colors.background.dark.green == 0)
        #expect(colors.background.dark.blue == 0)
        #expect(colors.text.light.red > 0.8)
        #expect(colors.title.light.blue > 0.8)
        #expect(colors.title.light.green > 0.8)
        #expect(colors.title.light.red < 0.6)
        #expect(colors.title == colors.action)
        #expect(colors.title != colors.text)
        #expect(Theme.starbyte.metrics.pixelChrome)
        #expect(Theme.starbyte.metrics.cardRadius == 0)
        #expect(Theme.starbyte.metrics.buttonRadius == 0)
        #expect(Theme.starbyte.metrics.tickerRadius == 0)
        #expect(Theme.starbyte.metrics.pitchRadius == 0)
        #expect(Theme.starbyte.metrics.minimumControl == 44)
        #expect(PixelFont.regular == "Silkscreen-Regular")
        #expect(PixelFont.bold == "Silkscreen-Bold")
        expectPositionInks(colors)
    }

    @Test func positionLabelsMatchTheInkOrder() {
        #expect(Position(labeled: "Keeper") == .keeper)
        #expect(Position(labeled: "GK") == .keeper)
        #expect(Position(labeled: "Defender") == .defender)
        #expect(Position(labeled: "DEF") == .defender)
        #expect(Position(labeled: "Midfielder") == .midfielder)
        #expect(Position(labeled: "MID") == .midfielder)
        #expect(Position(labeled: "Forward") == .forward)
        #expect(Position(labeled: "FWD") == .forward)
        #expect(Position(labeled: "Coach") == nil)
    }

    private func expectPositionInks(_ colors: Theme.Colors) {
        #expect(isPink(colors.keeper.light))
        #expect(isPink(colors.keeper.dark))
        #expect(isGreen(colors.defender.light))
        #expect(isGreen(colors.defender.dark))
        #expect(isBlue(colors.midfielder.light))
        #expect(isBlue(colors.midfielder.dark))
        #expect(isRed(colors.forward.light))
        #expect(isRed(colors.forward.dark))
        #expect(colors.keeper != colors.defender)
        #expect(colors.defender != colors.midfielder)
        #expect(colors.midfielder != colors.forward)
        #expect(colors.forward != colors.keeper)
    }

    private func isPink(_ ink: RGB) -> Bool {
        ink.red > ink.blue && ink.blue > ink.green + 0.08
    }

    private func isGreen(_ ink: RGB) -> Bool {
        ink.green > ink.red && ink.green > ink.blue
    }

    private func isBlue(_ ink: RGB) -> Bool {
        ink.blue > ink.red && ink.blue > ink.green
    }

    private func isRed(_ ink: RGB) -> Bool {
        ink.red > ink.green && ink.red > ink.blue && ink.blue <= ink.green
    }
}
