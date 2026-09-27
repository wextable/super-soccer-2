import Testing
import UIKit
@testable import SuperSoccer2

@Suite
@MainActor
struct ClubCrestTests {
    @Test func everyClubUsesACatalogCrestAndAMissingOneStaysBlank() {
        let season = LeagueDraft.makeLeague(seed: 1)
        #expect(Set(season.clubs.map(\.id)) == Set(ClubCrests.assetNames.keys))
        for club in season.clubs {
            #expect(ClubCrests.assetName(for: club.id) != nil)
            let image = ClubCrests.image(for: club.id)
            #expect(image != nil)
            #expect((image?.size.width ?? 0) > 0)
            #expect((image?.size.height ?? 0) > 0)
        }
        #expect(ClubCrests.assetName(for: "newcastle-united") == "team_icon_newcastle")
        #expect(ClubCrests.assetName(for: "not-a-club") == nil)
        #expect(ClubCrests.image(for: "not-a-club") == nil)
    }
}
