import Foundation
import Testing
@testable import SuperSoccer2

@Suite
struct FaceTests {
    @Test func theSameSeedDrawsTheSameFaces() {
        let first = faces(seed: 42)
        let second = faces(seed: 42)
        let other = faces(seed: 43)
        #expect(first == second)
        #expect(first != other)
        #expect(Set(first).count > 20)
        for face in first {
            #expect(face.background == 1)
            #expect(PlayerFaceCatalog.skins.indices.contains(face.skin))
            #expect((1...PlayerFaceCatalog.eyeCount).contains(face.eyes))
            #expect((1...PlayerFaceCatalog.mouthCount).contains(face.mouth))
            #expect((1...PlayerFaceCatalog.noseCount).contains(face.nose))
            if let eyebrows = face.eyebrows {
                #expect((1...PlayerFaceCatalog.eyebrowCount).contains(eyebrows))
            }
            if let mustache = face.mustache {
                #expect((1...PlayerFaceCatalog.mustacheCount).contains(mustache))
            }
            if let beard = face.beard {
                #expect((1...PlayerFaceCatalog.beardCount).contains(beard))
            }
            if let hair = face.hair {
                #expect((1...PlayerFaceCatalog.hairCount).contains(hair))
            }
        }
    }

    @Test func optionalPartsFollowTheOldChances() {
        var generator = SeededGenerator(seed: 1)
        var hair = 0
        var eyebrows = 0
        var mustache = 0
        var beard = 0
        let count = 4000
        for _ in 0..<count {
            let face = PlayerFaceGenerator.make(using: &generator)
            if face.hair != nil { hair += 1 }
            if face.eyebrows != nil { eyebrows += 1 }
            if face.mustache != nil { mustache += 1 }
            if face.beard != nil { beard += 1 }
        }
        #expect(near(hair, share: 0.90, of: count))
        #expect(near(eyebrows, share: 0.95, of: count))
        #expect(near(mustache, share: 0.10, of: count))
        #expect(near(beard, share: 0.15, of: count))
    }

    @Test func aSavedCareerKeepsTheSameFaces() async throws {
        let season = LeagueDraft.makeLeague(seed: 42)
        let career = MatchweekFeature.State(userClubID: season.clubs[0].id, season: season).career
        let original = season.clubs.flatMap(\.players).map(\.face)
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("ss2-faces-\(UUID().uuidString)", isDirectory: true)
        let url = folder.appendingPathComponent(CareerLocation.fileName)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let store = CareerStore.file(at: url)
        await store.save(career)
        let loaded = try #require(await store.load())
        #expect(loaded.clubs.flatMap(\.players).map(\.face) == original)
        #expect(url.lastPathComponent == "career.json")
    }

    @Test func aPlayerMissingAFaceDoesNotDecode() throws {
        let player = LeagueDraft.makeLeague(seed: 1).clubs[0].players[0]
        let encoded = try JSONEncoder().encode(player)
        let decoded = try JSONDecoder().decode(Player.self, from: encoded)
        #expect(decoded.face == player.face)

        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["face"] != nil)
        object.removeValue(forKey: "face")
        let missing = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Player.self, from: missing)
        }
    }

    @Test @MainActor func thePortraitPaintsSkinNeckAndKit() throws {
        let face = PlayerFace.plain
        let primary = FaceByte(10, 20, 30)
        let secondary = FaceByte(200, 10, 10)
        let image = try #require(
            PlayerFaceRenderer.image(face: face, primary: primary, secondary: secondary)
        )
        let skin = PlayerFaceCatalog.skins[face.skin]
        #expect(PlayerFaceRenderer.sample(image, x: 32, y: 22) == sample(skin.red, skin.green, skin.blue))
        #expect(PlayerFaceRenderer.sample(image, x: 32, y: 47) == sample(skin.red, skin.green, skin.blue))
        #expect(PlayerFaceRenderer.sample(image, x: 32, y: 55) == sample(secondary.red, secondary.green, secondary.blue))
        #expect(PlayerFaceRenderer.sample(image, x: 32, y: 61) == sample(primary.red, primary.green, primary.blue))
        #expect(PlayerFaceRenderer.sample(image, x: 0, y: 0)?.alpha == 0)
        let chin = PlayerFaceRenderer.sample(image, x: 32, y: 43)
        #expect((chin?.red ?? 255) < 40)
        #expect(chin?.alpha == 255)

        let again = try #require(
            PlayerFaceRenderer.image(face: face, primary: primary, secondary: secondary)
        )
        #expect(again.pngData() == image.pngData())

        let keeper = PlayerFaceTones.colors(position: .keeper, clubID: "arsenal")
        #expect(keeper.primary == FaceByte(230, 34, 214))
        #expect(keeper.secondary == FaceByte(255, 255, 255))
        let arsenal = PlayerFaceTones.colors(position: .forward, clubID: "arsenal")
        #expect(arsenal.primary == FaceByte(237, 11, 25))
        #expect(arsenal.secondary == FaceByte(255, 255, 255))
    }
}

private func faces(seed: UInt64) -> [PlayerFace] {
    LeagueDraft.makeLeague(seed: seed).clubs.flatMap(\.players).map(\.face)
}

private func near(_ count: Int, share: Double, of total: Int) -> Bool {
    let expected = share * Double(total)
    return abs(Double(count) - expected) < 200
}

private func sample(_ red: Int, _ green: Int, _ blue: Int) -> FaceSample {
    FaceSample(red: UInt8(red), green: UInt8(green), blue: UInt8(blue), alpha: 255)
}
