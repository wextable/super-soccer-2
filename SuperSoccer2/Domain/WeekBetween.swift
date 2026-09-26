import Foundation

/// Fitness, injuries, and skills for the week after a match. The match itself is unchanged.
enum WeekBetween {
    struct Settlement: Equatable, Sendable {
        var clubs: [Club]
        var offers: [SkillOffer]
    }

    static func afterStart(_ player: Player, tuning: WeekTuning = .current) -> Player {
        var player = player
        guard player.injury == nil else { return player }
        player.condition = max(0, player.condition - tuning.fitnessLossPerStart)
        return player
    }

    static func afterBench(_ player: Player, tuning: WeekTuning = .current) -> Player {
        var player = player
        guard player.injury == nil else { return player }
        player.condition = min(100, player.condition + tuning.benchRecovery)
        return player
    }

    /// Highest overall teammate in the same role who can play. Condition breaks a tie.
    static func bestFit(replacing player: Player, in players: [Player]) -> Player? {
        best(of: candidates(replacing: player, in: players))
    }

    /// Other fit teammates in that role, best overall first. The obvious swap is not in this list.
    static func alternatives(replacing player: Player, in players: [Player]) -> [Player] {
        let bestID = bestFit(replacing: player, in: players)?.id
        return candidates(replacing: player, in: players)
            .filter { $0.id != bestID }
            .sorted(by: bestFirst)
    }

    /// Sit a starter and bring in a teammate of the same role. An injured player cannot come in.
    static func replace(_ outgoingID: Player.ID, with incomingID: Player.ID, in club: Club) -> Club? {
        guard
            let outgoing = club.players.first(where: { $0.id == outgoingID }),
            let incoming = club.players.first(where: { $0.id == incomingID }),
            outgoing.isStarter,
            !incoming.isStarter,
            outgoing.injury == nil,
            incoming.injury == nil,
            outgoing.position == incoming.position
        else { return nil }
        var club = club
        club.players = club.players.map { player in
            var copy = player
            if copy.id == outgoingID { copy.isStarter = false }
            if copy.id == incomingID { copy.isStarter = true }
            return copy
        }
        return club
    }

    /// One yellow or red starter, and only when a fitter teammate in that role can play.
    /// A green side is left alone. A side full of tired players still rests one.
    static func restOneTired(_ club: Club, tuning: WeekTuning = .current) -> Club {
        let tired = club.starters
            .filter { $0.injury == nil && $0.fitnessBand(tuning: tuning) != .green }
            .sorted { lhs, rhs in
                if lhs.condition != rhs.condition { return lhs.condition < rhs.condition }
                return lhs.id < rhs.id
            }
        for starter in tired {
            let fitter = candidates(replacing: starter, in: club.players)
                .filter { $0.fitnessBand(tuning: tuning).isFitter(than: starter.fitnessBand(tuning: tuning)) }
            guard let incoming = best(of: fitter) else { continue }
            if let updated = replace(starter.id, with: incoming.id, in: club) {
                return updated
            }
        }
        return club
    }

    /// Apply the match that was just played. The user’s skill picks stay open. Other clubs spend theirs.
    static func settle(
        clubs: [Club],
        scorelines: [Matchweek.Scoreline],
        tallies: [LeagueLeaders.Tally],
        userClubID: String,
        seed: UInt64,
        tuning: WeekTuning = .current
    ) -> Settlement {
        var rng = SeededGenerator(seed: seed)
        var next = clubs
        var offers: [SkillOffer] = []
        for index in next.indices {
            let played = next[index].players.filter(\.isStarter)
            guard let conceded = goalsConceded(by: next[index].id, in: scorelines) else { continue }
            let playedIDs = Set(played.map(\.id))
            next[index].players = next[index].players.map { player in
                let justRecovered = advanceInjury(player, tuning: tuning)
                if playedIDs.contains(player.id) {
                    return afterStart(justRecovered.player, tuning: tuning)
                }
                if justRecovered.didRecover { return justRecovered.player }
                return afterBench(justRecovered.player, tuning: tuning)
            }
            awardXP(
                clubIndex: index,
                played: played,
                conceded: conceded,
                tallies: tallies,
                userClubID: userClubID,
                tuning: tuning,
                clubs: &next,
                offers: &offers
            )
            injurePlayersWhoPlayed(
                clubIndex: index,
                playedIDs: playedIDs,
                tuning: tuning,
                rng: &rng,
                clubs: &next
            )
            if next[index].id != userClubID {
                next[index] = restOneTired(next[index], tuning: tuning)
            }
        }
        return Settlement(clubs: next, offers: offers)
    }

    @discardableResult
    static func apply(
        _ stat: PlayerStat,
        offerID: String,
        offers: inout [SkillOffer],
        clubs: inout [Club],
        tuning: WeekTuning = .current
    ) -> Bool {
        guard let offerIndex = offers.firstIndex(where: { $0.id == offerID }) else { return false }
        let offer = offers[offerIndex]
        guard add(stat, to: offer.playerID, in: offer.clubID, clubs: &clubs, tuning: tuning) else { return false }
        offers.remove(at: offerIndex)
        return true
    }

    /// Spends every open skill on the stat that role prefers. Used for other clubs, and when the season is simulated.
    static func resolveAutomatically(
        _ offers: inout [SkillOffer],
        clubs: inout [Club],
        tuning: WeekTuning = .current
    ) {
        for offer in offers {
            guard let player = clubs.first(where: { $0.id == offer.clubID })?.players.first(where: { $0.id == offer.playerID })
            else { continue }
            add(PlayerStat.preferred(for: player.position), to: offer.playerID, in: offer.clubID, clubs: &clubs, tuning: tuning)
        }
        offers = []
    }

    private static func candidates(replacing player: Player, in players: [Player]) -> [Player] {
        players.filter { candidate in
            candidate.id != player.id
                && candidate.position == player.position
                && !candidate.isStarter
                && candidate.injury == nil
        }
    }

    private static func best(of players: [Player]) -> Player? {
        players.max(by: fitterFirst)
    }

    /// `true` when `lhs` is the lesser player, so `max(by:)` keeps the better one.
    private static func fitterFirst(_ lhs: Player, _ rhs: Player) -> Bool {
        if lhs.overall != rhs.overall { return lhs.overall < rhs.overall }
        if lhs.condition != rhs.condition { return lhs.condition < rhs.condition }
        return lhs.id > rhs.id
    }

    private static func bestFirst(_ lhs: Player, _ rhs: Player) -> Bool {
        fitterFirst(rhs, lhs)
    }

    private static func goalsConceded(by clubID: String, in scorelines: [Matchweek.Scoreline]) -> Int? {
        for line in scorelines {
            if line.homeID == clubID { return line.awayScore }
            if line.awayID == clubID { return line.homeScore }
        }
        return nil
    }

    /// Returns the player, and whether this call cleared the injury.
    private static func advanceInjury(_ player: Player, tuning: WeekTuning) -> (player: Player, didRecover: Bool) {
        guard var injury = player.injury else { return (player, false) }
        var player = player
        injury.weeksLeft -= 1
        if injury.weeksLeft <= 0 {
            player.injury = nil
            player.condition = tuning.conditionOnRecovery
            return (player, true)
        }
        player.injury = injury
        return (player, false)
    }

    private static func awardXP(
        clubIndex: Int,
        played: [Player],
        conceded: Int,
        tallies: [LeagueLeaders.Tally],
        userClubID: String,
        tuning: WeekTuning,
        clubs: inout [Club],
        offers: inout [SkillOffer]
    ) {
        let clubID = clubs[clubIndex].id
        let isUser = clubID == userClubID
        for starter in played {
            guard let playerIndex = clubs[clubIndex].players.firstIndex(where: { $0.id == starter.id }) else { continue }
            var player = clubs[clubIndex].players[playerIndex]
            player.xp += experience(
                for: starter,
                conceded: conceded,
                tallies: tallies,
                tuning: tuning
            )
            if isUser {
                var pending = 0
                while player.xp >= tuning.requiredXP(skillsEarned: player.skillsEarned + pending) {
                    let required = tuning.requiredXP(skillsEarned: player.skillsEarned + pending)
                    player.xp -= required
                    offers.append(
                        SkillOffer(
                            id: "\(clubID)|\(player.id)|\(player.skillsEarned + pending)",
                            playerID: player.id,
                            clubID: clubID
                        )
                    )
                    pending += 1
                }
            } else {
                while player.xp >= tuning.requiredXP(skillsEarned: player.skillsEarned) {
                    player.xp -= tuning.requiredXP(skillsEarned: player.skillsEarned)
                    add(PlayerStat.preferred(for: player.position), to: &player, tuning: tuning)
                }
            }
            clubs[clubIndex].players[playerIndex] = player
        }
    }

    private static func experience(
        for player: Player,
        conceded: Int,
        tallies: [LeagueLeaders.Tally],
        tuning: WeekTuning
    ) -> Int {
        let tally = tallies.first { $0.playerID == player.id }
        var gain = tuning.xpForStart
        gain += (tally?.goals ?? 0) * tuning.xpForGoal
        gain += (tally?.assists ?? 0) * tuning.xpForAssist
        gain += (tally?.saves ?? 0) * tuning.xpForSave
        if conceded == 0 {
            switch player.position {
            case .keeper: gain += tuning.xpForKeeperCleanSheet
            case .defender: gain += tuning.xpForDefenderCleanSheet
            case .midfielder, .forward: break
            }
        }
        return gain
    }

    private static func injurePlayersWhoPlayed(
        clubIndex: Int,
        playedIDs: Set<Player.ID>,
        tuning: WeekTuning,
        rng: inout SeededGenerator,
        clubs: inout [Club]
    ) {
        let ordered = clubs[clubIndex].players
            .filter { playedIDs.contains($0.id) && $0.injury == nil }
            .sorted { lhs, rhs in
                if lhs.condition != rhs.condition { return lhs.condition < rhs.condition }
                return lhs.id < rhs.id
            }
        for starter in ordered {
            guard let index = clubs[clubIndex].players.firstIndex(where: { $0.id == starter.id }) else { continue }
            let player = clubs[clubIndex].players[index]
            guard player.injury == nil, player.isStarter else { continue }
            let fitKeepers = clubs[clubIndex].players.filter { $0.position == .keeper && $0.injury == nil }.count
            if player.position == .keeper, fitKeepers <= 1 { continue }
            let chance = tuning.injuryChance(for: player.fitnessBand(tuning: tuning))
            let roll = Int.random(in: 1...100, using: &rng)
            guard roll <= chance else { continue }
            var hurt = player
            hurt.injury = Player.Injury(
                label: ailment(using: &rng),
                weeksLeft: weeks(using: &rng, tuning: tuning)
            )
            hurt.condition = 0
            clubs[clubIndex].players[index] = hurt
            if let replacement = bestFit(replacing: hurt, in: clubs[clubIndex].players),
               let slot = clubs[clubIndex].players.firstIndex(where: { $0.id == replacement.id }) {
                clubs[clubIndex].players[index].isStarter = false
                clubs[clubIndex].players[slot].isStarter = true
            }
        }
    }

    private static func ailment(using rng: inout SeededGenerator) -> String {
        let labels = [
            "pulled hamstring",
            "sprained ankle",
            "dead leg",
            "bruised ribs",
            "twisted knee",
        ]
        let index = Int.random(in: 0..<labels.count, using: &rng)
        return labels[index]
    }

    private static func weeks(using rng: inout SeededGenerator, tuning: WeekTuning) -> Int {
        let upper = max(tuning.injuryWeeksMin, tuning.injuryWeeksMax)
        return Int.random(in: tuning.injuryWeeksMin...upper, using: &rng)
    }

    @discardableResult
    private static func add(
        _ stat: PlayerStat,
        to playerID: Player.ID,
        in clubID: String,
        clubs: inout [Club],
        tuning: WeekTuning
    ) -> Bool {
        guard let clubIndex = clubs.firstIndex(where: { $0.id == clubID }),
              let playerIndex = clubs[clubIndex].players.firstIndex(where: { $0.id == playerID })
        else { return false }
        var player = clubs[clubIndex].players[playerIndex]
        add(stat, to: &player, tuning: tuning)
        clubs[clubIndex].players[playerIndex] = player
        return true
    }

    private static func add(_ stat: PlayerStat, to player: inout Player, tuning: WeekTuning) {
        let points = tuning.points(for: stat)
        switch stat {
        case .speed:
            player.ratings.speed = min(99, player.ratings.speed + points)
        case .shooting:
            player.ratings.shooting = min(99, player.ratings.shooting + points)
        case .passing:
            player.ratings.passing = min(99, player.ratings.passing + points)
        case .dribbling:
            player.ratings.dribbling = min(99, player.ratings.dribbling + points)
        case .defending:
            player.ratings.defending = min(99, player.ratings.defending + points)
        case .goalkeeping:
            player.ratings.goalkeeping = min(99, player.ratings.goalkeeping + points)
        }
        player.skillsEarned += 1
    }
}
