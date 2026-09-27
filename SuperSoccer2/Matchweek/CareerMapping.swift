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
            playedWeeks: state.playedWeeks
        )
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
        lineupRevision = 0
        skillsChosen = 0
        skillFollowUp = nil
        skillChoice = nil
        highlight = nil
        stats = nil
        leaders = nil
        championship = nil
        team = nil
        player = nil
        substitution = nil
        seasonAlert = nil
    }
}
