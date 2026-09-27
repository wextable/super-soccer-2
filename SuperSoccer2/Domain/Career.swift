import Foundation

/// The season already in memory: table, squads, fitness, injuries, skills, and awards.
struct Career: Codable, Equatable, Sendable {
    var userClubID: String
    var clubs: [Club]
    var weeks: [[LeagueDraft.Fixture]]
    var weekIndex: Int
    var standings: [Standing]
    var committedWeeks: Int
    var pending: Matchweek.Played?
    var totals: [String: LeagueLeaders.Counts]
    var playerClub: [String: String]
    var record: SeasonRecord?
    var skillOffers: [SkillOffer]
    var skillChoices: [SkillChoice]
    /// New injuries still unread. Dismissing them is what lets the week move on.
    var injuryNotices: [InjuryNotice] = []
}
