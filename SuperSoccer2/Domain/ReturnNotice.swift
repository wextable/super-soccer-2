import Foundation

/// One player who is fit again. Read at the start of the new week, after it has advanced.
struct ReturnNotice: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var playerName: String
    var positionTitle: String
    var ailment: String
    /// The week that was just played. The notice waits until the season moves past it.
    var weekIndex: Int

    var headline: String {
        "\(playerName) is back from a \(ailment)."
    }

    /// Injuries that were on the squad before this week and are gone after it.
    static func arriving(before: [Player], after: [Player], weekIndex: Int) -> [ReturnNotice] {
        let healed = Dictionary(uniqueKeysWithValues: before.compactMap { player -> (String, Player.Injury)? in
            guard let injury = player.injury else { return nil }
            return (player.id, injury)
        })
        return after.compactMap { player in
            guard let injury = healed[player.id], player.injury == nil else { return nil }
            return ReturnNotice(
                id: "return|\(weekIndex)|\(player.id)",
                playerName: player.fullName,
                positionTitle: player.position.title,
                ailment: injury.label,
                weekIndex: weekIndex
            )
        }
    }
}
