import Foundation

/// The parts the old face factory picked. Kit colors are painted from the club at draw time.
struct PlayerFace: Codable, Equatable, Hashable, Sendable {
    /// 1-based catalog index. The old factory had one background.
    var background: Int
    /// Index into the sixteen skin colors.
    var skin: Int
    var eyes: Int
    /// Nil when the roll skipped eyebrows.
    var eyebrows: Int?
    var mouth: Int
    var mustache: Int?
    var nose: Int
    var beard: Int?
    var hair: Int?

    /// A finished portrait for a player built outside the draft.
    static let plain = PlayerFace(
        background: 1,
        skin: 0,
        eyes: 1,
        eyebrows: 1,
        mouth: 1,
        mustache: nil,
        nose: 1,
        beard: nil,
        hair: 1
    )
}

/// Counts and colors copied from `FaceFactory`.
enum PlayerFaceCatalog {
    static let backgroundCount = 1
    static let hairCount = 2
    static let eyeCount = 2
    static let eyebrowCount = 2
    static let mouthCount = 2
    static let mustacheCount = 1
    static let noseCount = 2
    static let beardCount = 1

    static let skins: [(red: Int, green: Int, blue: Int)] = [
        (254, 227, 200),
        (253, 230, 176),
        (248, 216, 156),
        (249, 211, 164),
        (236, 192, 148),
        (241, 194, 133),
        (211, 158, 125),
        (185, 101, 59),
        (206, 150, 100),
        (173, 138, 99),
        (146, 95, 58),
        (114, 63, 28),
        (177, 102, 72),
        (126, 69, 38),
        (94, 51, 20),
        (81, 43, 15),
    ]

    static func asset(_ part: String, _ index: Int) -> String {
        "face_\(part)_\(index)"
    }
}

/// The same rolls as `FaceFactory.makeFace`, on a seeded generator.
enum PlayerFaceGenerator {
    /// Separate from the rating generator, the way development traits are.
    static let salt: UInt64 = 0xF4CE_5A17

    static func make(using generator: inout SeededGenerator) -> PlayerFace {
        let background = Int.random(in: 1...PlayerFaceCatalog.backgroundCount, using: &generator)
        let skin = Int.random(in: 0..<PlayerFaceCatalog.skins.count, using: &generator)
        let eyes = Int.random(in: 1...PlayerFaceCatalog.eyeCount, using: &generator)
        let eyebrows = optionalPart(chance: 95, count: PlayerFaceCatalog.eyebrowCount, using: &generator)
        let mouth = Int.random(in: 1...PlayerFaceCatalog.mouthCount, using: &generator)
        let mustache = optionalPart(chance: 10, count: PlayerFaceCatalog.mustacheCount, using: &generator)
        let nose = Int.random(in: 1...PlayerFaceCatalog.noseCount, using: &generator)
        let beard = optionalPart(chance: 15, count: PlayerFaceCatalog.beardCount, using: &generator)
        let hair = optionalPart(chance: 90, count: PlayerFaceCatalog.hairCount, using: &generator)
        return PlayerFace(
            background: background,
            skin: skin,
            eyes: eyes,
            eyebrows: eyebrows,
            mouth: mouth,
            mustache: mustache,
            nose: nose,
            beard: beard,
            hair: hair
        )
    }

    /// `Int.random(in: 0..<100) < chance`, then a 1-based part index. Hair is 90, eyebrows 95, beard 15, mustache 10.
    private static func optionalPart(
        chance: Int,
        count: Int,
        using generator: inout SeededGenerator
    ) -> Int? {
        guard Int.random(in: 0..<100, using: &generator) < chance else { return nil }
        return Int.random(in: 1...count, using: &generator)
    }
}
