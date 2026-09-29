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
