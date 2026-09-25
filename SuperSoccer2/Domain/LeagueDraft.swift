import Foundation

/// Seeded port of the previous league build: a rating pool, then a tier draft.
/// Clubs stay in TeamFactory order. Index 0 drafts first. The week screen reads this league.
enum LeagueDraft {
    static let clubCount = 20
    static let playersPerClub = 20
    static let startersPerClub = 11
    static let maxKeepers = 2
    static let maxPerOutfieldLine = 6
    static let maxStartingKeepers = 1
    static let maxStartingPerLine = 4

    struct Fixture: Equatable, Sendable {
        var homeID: String
        var awayID: String
    }

    struct Season: Equatable, Sendable {
        /// Prestige order. Manchester City is first, Norwich City is last.
        var clubs: [Club]
        var rosterCounts: [Int]
        /// Circle method, then the list appended once. The same club hosts both meetings.
        var fixtures: [Fixture]
    }

    static func clubName(at index: Int) -> String {
        guard templates.indices.contains(index) else { return "Club \(index)" }
        return templates[index].name
    }

    static func makeLeague(seed: UInt64) -> Season {
        var generator = SeededGenerator(seed: seed)
        var pool = makePool(using: &generator)
        pool.sort { $0.overall > $1.overall }

        var rosters = Array(repeating: [Player](), count: templates.count)
        var round = 1
        var spins = 0
        while rosters.contains(where: { $0.count < playersPerClub }) {
            spins += 1
            if spins > 60 { break }
            let drafting = draftingCount(round: round, clubs: templates.count)
            var placed = 0
            for index in 0..<drafting {
                guard rosters[index].count < playersPerClub else { continue }
                guard let picked = takePlayer(for: rosters[index], from: &pool) else { continue }
                var player = picked
                player.id = "\(templates[index].id)-\(rosters[index].count)"
                rosters[index].append(player)
                placed += 1
            }
            if placed == 0 { break }
            round += 1
        }

        let clubs = zip(templates, rosters).map { template, roster in
            makeClub(template: template, roster: sortRoster(roster))
        }
        let ids = clubs.map(\.id).shuffled(using: &generator)
        return Season(
            clubs: clubs,
            rosterCounts: rosters.map(\.count),
            fixtures: seasonFixtures(teamIDs: ids)
        )
    }

    /// Rounds 1–2: first 30%. Round 3: first 60%. Rounds 4–5: first 75%. Then everyone.
    static func draftingCount(round: Int, clubs: Int) -> Int {
        let share: Double
        if round < 3 {
            share = 0.3
        } else if round < 4 {
            share = 0.6
        } else if round < 6 {
            share = 0.75
        } else {
            share = 1
        }
        return Int(Double(clubs) * share)
    }

    private static func makePool(using generator: inout SeededGenerator) -> [Player] {
        var positions: [Position] = []
        positions += Array(repeating: .keeper, count: templates.count * maxKeepers)
        positions += Array(repeating: .defender, count: templates.count * maxPerOutfieldLine)
        positions += Array(repeating: .midfielder, count: templates.count * maxPerOutfieldLine)
        positions += Array(repeating: .forward, count: templates.count * maxPerOutfieldLine)

        return positions.enumerated().map { index, position in
            Player(
                id: "pool-\(index)",
                firstName: "",
                lastName: "",
                position: position,
                condition: 100,
                ratings: makeRatings(position: position, using: &generator)
            ).named(using: &generator)
        }
    }

    /// The previous PlayerFactory ranges, in the same draw order. Half-open, so the top integer is excluded.
    static func makeRatings(position: Position, using generator: inout SeededGenerator) -> Ratings {
        switch position {
        case .keeper:
            Ratings(
                speed: Int.random(in: 20..<60, using: &generator),
                shooting: Int.random(in: 20..<50, using: &generator),
                passing: Int.random(in: 40..<80, using: &generator),
                dribbling: Int.random(in: 20..<60, using: &generator),
                defending: Int.random(in: 55..<100, using: &generator),
                goalkeeping: Int.random(in: 60..<100, using: &generator)
            )
        case .defender:
            Ratings(
                speed: Int.random(in: 45..<95, using: &generator),
                shooting: Int.random(in: 30..<75, using: &generator),
                passing: Int.random(in: 50..<95, using: &generator),
                dribbling: Int.random(in: 40..<90, using: &generator),
                defending: Int.random(in: 55..<100, using: &generator),
                goalkeeping: Int.random(in: 20..<40, using: &generator)
            )
        case .midfielder:
            Ratings(
                speed: Int.random(in: 50..<95, using: &generator),
                shooting: Int.random(in: 50..<100, using: &generator),
                passing: Int.random(in: 55..<100, using: &generator),
                dribbling: Int.random(in: 50..<95, using: &generator),
                defending: Int.random(in: 50..<95, using: &generator),
                goalkeeping: Int.random(in: 20..<40, using: &generator)
            )
        case .forward:
            Ratings(
                speed: Int.random(in: 55..<100, using: &generator),
                shooting: Int.random(in: 50..<100, using: &generator),
                passing: Int.random(in: 45..<100, using: &generator),
                dribbling: Int.random(in: 50..<100, using: &generator),
                defending: Int.random(in: 20..<70, using: &generator),
                goalkeeping: Int.random(in: 20..<30, using: &generator)
            )
        }
    }

    /// Starters: one keeper, and at most three of an outfield line until the eleventh, who may be the fourth.
    /// Reserves fill two keepers and six of each line.
    private static func takePlayer(for roster: [Player], from pool: inout [Player]) -> Player? {
        let pick: Player?
        if roster.count >= startersPerClub {
            pick = pool.first { candidate in
                let existing = roster.filter { $0.position == candidate.position }.count
                switch candidate.position {
                case .keeper:
                    return existing < maxKeepers
                default:
                    return existing < maxPerOutfieldLine
                }
            }
        } else {
            let isLastStarter = roster.count == startersPerClub - 1
            pick = pool.first { candidate in
                let existing = roster.filter { $0.position == candidate.position }.count
                switch candidate.position {
                case .keeper:
                    return existing < maxStartingKeepers
                default:
                    if isLastStarter {
                        return existing < maxStartingPerLine
                    }
                    return existing < maxStartingPerLine - 1
                }
            }
        }
        guard let pick, let index = pool.firstIndex(where: { $0.id == pick.id }) else { return nil }
        pool.remove(at: index)
        var player = pick
        if roster.count < startersPerClub {
            player.isStarter = true
        }
        return player
    }

    /// Position, then the old half-star bands, higher first. Potential is not rolled, so a star tie keeps draft order.
    private static func sortRoster(_ roster: [Player]) -> [Player] {
        roster.sorted { lhs, rhs in
            let left = lhs.position.ordinal
            let right = rhs.position.ordinal
            if left != right { return left < right }
            return starBand(lhs.overall) > starBand(rhs.overall)
        }
    }

    static func starBand(_ overall: Int) -> Double {
        switch overall {
        case ..<64: 0.5
        case 64..<67: 1
        case 67..<70: 1.5
        case 70..<73: 2
        case 73..<76: 2.5
        case 76..<79: 3
        case 79..<82: 3.5
        case 82..<85: 4
        case 85..<88: 4.5
        default: 5
        }
    }

    private static func makeClub(template: Template, roster: [Player]) -> Club {
        Club(
            id: template.id,
            name: template.name,
            shortName: template.shortName,
            listName: template.listName,
            nickname: template.nickname,
            kit: template.kit,
            starters: roster.filter(\.isStarter)
        )
    }

    static let matchesPerWeek = clubCount / 2

    static func weeks(in fixtures: [Fixture]) -> [[Fixture]] {
        guard matchesPerWeek > 0 else { return [] }
        return stride(from: 0, to: fixtures.count, by: matchesPerWeek).map { start in
            Array(fixtures[start..<min(start + matchesPerWeek, fixtures.count)])
        }
    }

    /// Nineteen circle-method weeks, then that list appended once. Even leagues have no bye.
    static func seasonFixtures(teamIDs: [String]) -> [Fixture] {
        var ids: [String?] = teamIDs.map { Optional.some($0) }
        if ids.count % 2 == 1 {
            ids.append(nil)
        }
        let half = ids.count / 2
        var groupA = Array(ids.prefix(half))
        var groupB = Array(ids.suffix(half).reversed())
        var weeks: [[Fixture]] = []
        weeks.append(weeklyPairings(groupA: groupA, groupB: groupB))
        for _ in 1..<ids.count - 1 {
            let lastA = groupA.removeLast()
            let firstB = groupB.removeFirst()
            groupA.insert(firstB, at: 1)
            groupB.append(lastA)
            weeks.append(weeklyPairings(groupA: groupA, groupB: groupB))
        }
        weeks.append(contentsOf: weeks)
        return weeks.flatMap { $0 }
    }

    private static func weeklyPairings(groupA: [String?], groupB: [String?]) -> [Fixture] {
        var fixtures: [Fixture] = []
        for index in 0..<groupA.count {
            let pair = index % 2 == 0
                ? (groupA[index], groupB[index])
                : (groupB[index], groupA[index])
            if let home = pair.0, let away = pair.1 {
                fixtures.append(Fixture(homeID: home, awayID: away))
            }
        }
        return fixtures
    }
}

private extension Player {
    func named(using generator: inout SeededGenerator) -> Player {
        var copy = self
        copy.firstName = NameGenerator.makeFirstName(using: &generator)
        copy.lastName = NameGenerator.makeLastName(using: &generator)
        return copy
    }
}

private extension Position {
    var ordinal: Int {
        switch self {
        case .keeper: 0
        case .defender: 1
        case .midfielder: 2
        case .forward: 3
        }
    }
}

private struct Template {
    var id: String
    var name: String
    var shortName: String
    var listName: String
    var nickname: String
    var kit: Kit
}

private extension LeagueDraft {
    static let templates: [Template] = [
        club("manchester-city", "Manchester City", "MCT", "Man City", "Citizens", 100, 173, 221, 2, 33, 63),
        club("liverpool", "Liverpool", "LIV", "Liverpool", "Reds", 219, 10, 22, 21, 150, 127),
        club("chelsea", "Chelsea", "CHE", "Chelsea", "Blues", 8, 71, 147, 240, 228, 53),
        club("arsenal", "Arsenal", "ARS", "Arsenal", "Gunners", 237, 11, 25, 255, 255, 255),
        club("manchester-united", "Manchester United", "MUN", "Man United", "Red Devils", 252, 13, 27, 254, 228, 51),
        club("west-ham", "West Ham", "WHM", "West Ham", "Irons", 151, 6, 20, 157, 208, 242),
        club("tottenham", "Tottenham", "TOT", "Tottenham", "Lilywhites", 255, 255, 255, 1, 24, 76),
        club("wolverhampton", "Wolverhampton", "WLV", "Wolves", "Wolves", 253, 153, 39, 0, 0, 0),
        club("leicester-city", "Leicester City", "LCT", "Leicester", "Foxes", 11, 36, 251, 255, 255, 255),
        club("crystal-palace", "Crystal Palace", "CPL", "Palace", "Eagles", 252, 13, 27, 14, 77, 251),
        club("brighton", "Brighton", "BRT", "Brighton", "Seagulls", 10, 33, 238, 255, 255, 255),
        club("aston-villa", "Aston Villa", "AVL", "Villa", "Lions", 166, 204, 253, 132, 4, 30),
        club("southampton", "Southampton", "STH", "Southampton", "Saints", 252, 13, 27, 224, 224, 224),
        club("brentford", "Brentford", "BRF", "Brentford", "Bees", 252, 13, 27, 255, 255, 255),
        club("everton", "Everton", "EVT", "Everton", "Blues", 8, 30, 219, 255, 255, 255),
        club("leeds-united", "Leeds United", "LEE", "Leeds", "Whites", 255, 255, 255, 20, 36, 86),
        club("watford", "Watford", "WTF", "Watford", "Hornets", 253, 226, 58, 0, 0, 0),
        club("burnley", "Burnley", "BRN", "Burnley", "Clarets", 128, 3, 29, 132, 193, 253),
        club("newcastle-united", "Newcastle United", "NCS", "Newcastle", "Magpies", 0, 0, 0, 255, 255, 255),
        club("norwich-city", "Norwich City", "NWC", "Norwich", "Canaries", 255, 240, 53, 21, 152, 70),
    ]

    static func club(
        _ id: String,
        _ name: String,
        _ shortName: String,
        _ listName: String,
        _ nickname: String,
        _ red: Double,
        _ green: Double,
        _ blue: Double,
        _ red2: Double,
        _ green2: Double,
        _ blue2: Double
    ) -> Template {
        Template(
            id: id,
            name: name,
            shortName: shortName,
            listName: listName,
            nickname: nickname,
            kit: Kit(
                primary: KitColor(red: red / 255, green: green / 255, blue: blue / 255),
                secondary: KitColor(red: red2 / 255, green: green2 / 255, blue: blue2 / 255)
            )
        )
    }
}
