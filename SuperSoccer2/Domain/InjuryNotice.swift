import Foundation

/// One new injury the user still has to read before the week moves on.
struct InjuryNotice: Codable, Equatable, Sendable, Identifiable {
    var id: String
    var playerName: String
    var positionTitle: String
    var ailment: String
    var cause: String
    var weeksLeft: Int

    var headline: String {
        "\(playerName) has a \(ailment)."
    }

    var healLine: String {
        weeksLeft == 1 ? "It will take 1 week to heal." : "It will take \(weeksLeft) weeks to heal."
    }

    /// Injuries that were not on the squad before this match.
    static func arriving(before: [Player], after: [Player], weekIndex: Int) -> [InjuryNotice] {
        let already = Set(before.compactMap { player in
            player.injury == nil ? nil : player.id
        })
        return after.compactMap { player in
            guard let injury = player.injury, already.contains(player.id) == false else { return nil }
            return InjuryNotice(
                id: "\(weekIndex)|\(player.id)",
                playerName: player.fullName,
                positionTitle: player.position.title,
                ailment: injury.label,
                cause: injury.cause,
                weeksLeft: injury.weeksLeft
            )
        }
    }
}
