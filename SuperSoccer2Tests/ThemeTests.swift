import Testing
@testable import SuperSoccer2

@Suite
struct ThemeTests {
    @Test func starbyteKeepsLightAndDarkOnEachRole() {
        let colors = Theme.starbyte.colors
        #expect(colors.background.light != colors.background.dark)
        #expect(colors.text.light != colors.text.dark)
        #expect(colors.secondaryText.light != colors.secondaryText.dark)
        #expect(colors.action.light != colors.action.dark)
        #expect(colors.score.light != colors.score.dark)
        #expect(colors.card.light != colors.card.dark)
        #expect(colors.pitch.light == colors.pitch.dark)
        #expect(colors.score.light != colors.text.light)
        #expect(colors.action.dark == colors.ticker.dark)
        #expect(Theme.starbyte.metrics.minimumControl == 44)
    }
}
