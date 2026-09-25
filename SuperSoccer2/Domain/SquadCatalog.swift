import Foundation

/// The two clubs on the first screen are the ends of a drafted league.
enum SquadCatalog {
    static func makePair(seed: UInt64) -> [Club] {
        let clubs = LeagueDraft.makeLeague(seed: seed).clubs
        guard
            let city = clubs.first(where: { $0.id == "manchester-city" }),
            let norwich = clubs.first(where: { $0.id == "norwich-city" })
        else {
            return []
        }
        return [city, norwich]
    }
}
