import Foundation

/// Two real clubs. Ratings are written by hand so the favorite is obvious. Names come from the generator.
enum SquadCatalog {
    static let starterPositions: [Position] = [
        .keeper,
        .defender, .defender, .defender, .defender,
        .midfielder, .midfielder, .midfielder,
        .forward, .forward, .forward,
    ]

    static func makePair(seed: UInt64) -> [Club] {
        var generator = SeededGenerator(seed: seed)
        return [
            makeClub(
                id: "manchester-city",
                name: "Manchester City",
                shortName: "MCI",
                nickname: "Citizens",
                kit: Kit(
                    primary: KitColor(red: 100 / 255, green: 173 / 255, blue: 221 / 255),
                    secondary: KitColor(red: 2 / 255, green: 33 / 255, blue: 63 / 255)
                ),
                ratings: cityRatings,
                using: &generator
            ),
            makeClub(
                id: "norwich-city",
                name: "Norwich City",
                shortName: "NOR",
                nickname: "Canaries",
                kit: Kit(
                    primary: KitColor(red: 255 / 255, green: 240 / 255, blue: 53 / 255),
                    secondary: KitColor(red: 21 / 255, green: 152 / 255, blue: 70 / 255)
                ),
                ratings: norwichRatings,
                using: &generator
            ),
        ]
    }

    private static func makeClub(
        id: String,
        name: String,
        shortName: String,
        nickname: String,
        kit: Kit,
        ratings: [Ratings],
        using generator: inout SeededGenerator
    ) -> Club {
        let starters = zip(starterPositions, ratings).enumerated().map { index, pair in
            Player(
                id: "\(id)-\(index)",
                firstName: NameGenerator.makeFirstName(using: &generator),
                lastName: NameGenerator.makeLastName(using: &generator),
                position: pair.0,
                condition: 100,
                ratings: pair.1
            )
        }
        return Club(
            id: id,
            name: name,
            shortName: shortName,
            nickname: nickname,
            kit: kit,
            starters: starters
        )
    }
}

private let cityRatings: [Ratings] = [
    Ratings(speed: 36, shooting: 16, passing: 56, dribbling: 22, defending: 58, goalkeeping: 76),
    Ratings(speed: 66, shooting: 40, passing: 64, dribbling: 52, defending: 74, goalkeeping: 12),
    Ratings(speed: 68, shooting: 44, passing: 66, dribbling: 54, defending: 76, goalkeeping: 12),
    Ratings(speed: 64, shooting: 38, passing: 62, dribbling: 50, defending: 73, goalkeeping: 12),
    Ratings(speed: 67, shooting: 42, passing: 65, dribbling: 53, defending: 75, goalkeeping: 14),
    Ratings(speed: 72, shooting: 68, passing: 74, dribbling: 70, defending: 55, goalkeeping: 12),
    Ratings(speed: 74, shooting: 72, passing: 76, dribbling: 73, defending: 58, goalkeeping: 12),
    Ratings(speed: 70, shooting: 66, passing: 72, dribbling: 68, defending: 54, goalkeeping: 12),
    Ratings(speed: 76, shooting: 74, passing: 64, dribbling: 70, defending: 32, goalkeeping: 12),
    Ratings(speed: 74, shooting: 72, passing: 62, dribbling: 68, defending: 30, goalkeeping: 12),
    Ratings(speed: 72, shooting: 70, passing: 60, dribbling: 66, defending: 28, goalkeeping: 12),
]

private let norwichRatings: [Ratings] = [
    Ratings(speed: 34, shooting: 14, passing: 52, dribbling: 22, defending: 60, goalkeeping: 74),
    Ratings(speed: 58, shooting: 34, passing: 54, dribbling: 42, defending: 78, goalkeeping: 14),
    Ratings(speed: 60, shooting: 36, passing: 56, dribbling: 44, defending: 80, goalkeeping: 14),
    Ratings(speed: 56, shooting: 32, passing: 52, dribbling: 40, defending: 76, goalkeeping: 14),
    Ratings(speed: 57, shooting: 33, passing: 53, dribbling: 41, defending: 77, goalkeeping: 14),
    Ratings(speed: 60, shooting: 50, passing: 58, dribbling: 52, defending: 55, goalkeeping: 14),
    Ratings(speed: 62, shooting: 52, passing: 60, dribbling: 54, defending: 57, goalkeeping: 14),
    Ratings(speed: 58, shooting: 48, passing: 56, dribbling: 50, defending: 53, goalkeeping: 14),
    Ratings(speed: 64, shooting: 58, passing: 52, dribbling: 56, defending: 36, goalkeeping: 12),
    Ratings(speed: 66, shooting: 60, passing: 54, dribbling: 58, defending: 38, goalkeeping: 12),
    Ratings(speed: 62, shooting: 56, passing: 50, dribbling: 54, defending: 34, goalkeeping: 12),
]
