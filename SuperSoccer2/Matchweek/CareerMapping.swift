import Foundation

extension Career {
    init(matchweek state: MatchweekFeature.State) {
        self.init(
            userClubID: state.userClubID,
            clubs: state.clubs,
            weeks: state.weeks,
            weekIndex: state.weekIndex,
            standings: state.standings,
            committedWeeks: state.committedWeeks,
            pending: state.pending,
            totals: state.totals,
            playerClub: state.playerClub,
            record: state.record,
            skillOffers: state.skillOffers,
            skillChoices: state.skillChoices,
            injuryNotices: state.injuryNotices,
            returnNotices: state.returnNotices,
            playedWeeks: state.playedWeeks
        )
    }
}

extension Career {
    private enum CodingKeys: String, CodingKey {
        case userClubID
        case clubs
        case weeks
        case weekIndex
        case standings
        case committedWeeks
        case pending
        case totals
        case playerClub
        case record
        case skillOffers
        case skillChoices
        case injuryNotices
        case returnNotices
        case playedWeeks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userClubID = try container.decode(String.self, forKey: .userClubID)
        clubs = try container.decode([Club].self, forKey: .clubs)
        weeks = try container.decode([[LeagueDraft.Fixture]].self, forKey: .weeks)
        weekIndex = try container.decode(Int.self, forKey: .weekIndex)
        standings = try container.decode([Standing].self, forKey: .standings)
        committedWeeks = try container.decode(Int.self, forKey: .committedWeeks)
        pending = try container.decodeIfPresent(Matchweek.Played.self, forKey: .pending)
        totals = try container.decode([String: LeagueLeaders.Counts].self, forKey: .totals)
        playerClub = try container.decode([String: String].self, forKey: .playerClub)
        record = try container.decodeIfPresent(SeasonRecord.self, forKey: .record)
        skillOffers = try container.decode([SkillOffer].self, forKey: .skillOffers)
        skillChoices = try container.decode([SkillChoice].self, forKey: .skillChoices)
        injuryNotices = try container.decodeIfPresent([InjuryNotice].self, forKey: .injuryNotices) ?? []
        returnNotices = try container.decodeIfPresent([ReturnNotice].self, forKey: .returnNotices) ?? []
        playedWeeks = try container.decodeIfPresent([[Matchweek.Scoreline]].self, forKey: .playedWeeks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userClubID, forKey: .userClubID)
        try container.encode(clubs, forKey: .clubs)
        try container.encode(weeks, forKey: .weeks)
        try container.encode(weekIndex, forKey: .weekIndex)
        try container.encode(standings, forKey: .standings)
        try container.encode(committedWeeks, forKey: .committedWeeks)
        try container.encodeIfPresent(pending, forKey: .pending)
        try container.encode(totals, forKey: .totals)
        try container.encode(playerClub, forKey: .playerClub)
        try container.encodeIfPresent(record, forKey: .record)
        try container.encode(skillOffers, forKey: .skillOffers)
        try container.encode(skillChoices, forKey: .skillChoices)
        try container.encode(injuryNotices, forKey: .injuryNotices)
        try container.encode(returnNotices, forKey: .returnNotices)
        try container.encodeIfPresent(playedWeeks, forKey: .playedWeeks)
    }
}

extension MatchweekFeature.State {
    init(career: Career) {
        userClubID = career.userClubID
        clubs = career.clubs
        weeks = career.weeks
        weekIndex = career.weekIndex
        browsedWeekIndex = nil
        playedWeeks = career.playedWeeks ?? []
        standings = career.standings
        committedWeeks = career.committedWeeks
        pending = career.pending
        totals = career.totals
        playerClub = career.playerClub
        record = career.record
        didFail = false
        tab = .club
        skillOffers = career.skillOffers
        skillChoices = career.skillChoices
        injuryNotices = career.injuryNotices
        returnNotices = career.returnNotices
        lineupRevision = 0
        skillsChosen = 0
        skillFollowUp = nil
        skillChoice = nil
        injuryNotice = nil
        returnNotice = nil
        highlight = nil
        stats = nil
        leaders = nil
        championship = nil
        team = nil
        player = nil
        substitution = nil
        seasonAlert = nil
        if seasonIsOver {
            returnNotices = []
        } else if let queuedWeek = returnNotices.map(\.weekIndex).max(), weekIndex > queuedWeek {
            presentNextReturn()
        }
    }
}
