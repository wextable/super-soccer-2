import ComposableArchitecture
import Foundation

@Reducer
struct MatchweekFeature {
    @ObservableState
    struct State: Equatable {
        var userClubID: String
        var clubs: [Club]
        var weeks: [[LeagueDraft.Fixture]]
        var weekIndex: Int
        var standings: [Standing]
        var committedWeeks: Int
        var pending: Matchweek.Played?
        var didFail: Bool
        var tab: Tab
        @Presents var highlight: HighlightFeature.State?
        @Presents var stats: MatchStatsFeature.State?
        @Presents var player: PlayerDetailFeature.State?

        enum Tab: Equatable, Hashable, Sendable, CaseIterable {
            case club
            case table
            case week
            case match
        }

        struct WeekLine: Equatable, Identifiable, Sendable {
            var homeID: String
            var awayID: String
            var homeScore: Int?
            var awayScore: Int?

            var id: String { "\(homeID)-\(awayID)" }
        }

        init(userClubID: String, season: LeagueDraft.Season) {
            self.userClubID = userClubID
            clubs = season.clubs
            weeks = LeagueDraft.weeks(in: season.fixtures)
            weekIndex = 0
            standings = LeagueTable.zeros(clubIDs: season.clubs.map(\.id))
            committedWeeks = 0
            pending = nil
            didFail = false
            tab = .match
            highlight = nil
            stats = nil
            player = nil
        }

        var weekNumber: Int { weekIndex + 1 }

        var currentWeekIsInTheTable: Bool { committedWeeks > weekIndex }

        var hasNextFixture: Bool {
            currentWeekIsInTheTable && weekIndex + 1 < weeks.count
        }

        var seasonIsOver: Bool {
            currentWeekIsInTheTable && weekIndex + 1 >= weeks.count
        }

        var table: [Standing] {
            LeagueTable.ranked(standings, clubs: clubs)
        }

        var userClub: Club? {
            clubs.first { $0.id == userClubID }
        }

        var userStanding: Standing? {
            standings.first { $0.clubID == userClubID }
        }

        var fixture: LeagueDraft.Fixture? {
            guard weeks.indices.contains(weekIndex) else { return nil }
            return weeks[weekIndex].first { $0.homeID == userClubID || $0.awayID == userClubID }
        }

        var userIsHome: Bool {
            fixture?.homeID == userClubID
        }

        var opponent: Club? {
            guard let fixture else { return nil }
            let opponentID = fixture.homeID == userClubID ? fixture.awayID : fixture.homeID
            return clubs.first { $0.id == opponentID }
        }

        /// Highest overalls on the next opponent. A tie keeps roster order.
        var keyPlayers: [Player] {
            guard let opponent else { return [] }
            return opponent.starters
                .enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.overall != rhs.element.overall {
                        return lhs.element.overall > rhs.element.overall
                    }
                    return lhs.offset < rhs.offset
                }
                .prefix(3)
                .map(\.element)
        }

        var weekLines: [WeekLine] {
            guard weeks.indices.contains(weekIndex) else { return [] }
            let played = currentWeekIsInTheTable ? pending?.scorelines ?? [] : []
            let scores = Dictionary(uniqueKeysWithValues: played.map { ("\($0.homeID)-\($0.awayID)", $0) })
            return weeks[weekIndex].enumerated().map { offset, fixture in
                let score = scores["\(fixture.homeID)-\(fixture.awayID)"]
                return (
                    offset,
                    WeekLine(
                        homeID: fixture.homeID,
                        awayID: fixture.awayID,
                        homeScore: score?.homeScore,
                        awayScore: score?.awayScore
                    )
                )
            }
            .sorted { lhs, rhs in
                let leftIsUser = lhs.1.homeID == userClubID || lhs.1.awayID == userClubID
                let rightIsUser = rhs.1.homeID == userClubID || rhs.1.awayID == userClubID
                if leftIsUser != rightIsUser { return leftIsUser }
                return lhs.0 < rhs.0
            }
            .map(\.1)
        }

        var scorelines: [Matchweek.Scoreline] {
            guard currentWeekIsInTheTable, let lines = pending?.scorelines else { return [] }
            return lines.enumerated().sorted { lhs, rhs in
                let leftIsUser = lhs.element.involves(userClubID)
                let rightIsUser = rhs.element.involves(userClubID)
                if leftIsUser != rightIsUser { return leftIsUser }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
        }

        var places: [String: Int] {
            Dictionary(uniqueKeysWithValues: table.enumerated().map { ($1.clubID, $0 + 1) })
        }

        /// Week-list label: league place, then the short club name.
        var fixtureNames: [String: String] {
            Dictionary(uniqueKeysWithValues: clubs.map { club in
                let name = places[club.id].map { "\($0) \(club.listName)" } ?? club.listName
                return (club.id, name)
            })
        }

        fileprivate mutating func commitPendingWeek() {
            guard let pending, !currentWeekIsInTheTable else { return }
            standings = LeagueTable.applying(pending.scorelines, to: standings)
            committedWeeks = weekIndex + 1
        }
    }

    enum Action {
        case view(View)
        case highlight(PresentationAction<HighlightFeature.Action>)
        case stats(PresentationAction<MatchStatsFeature.Action>)
        case player(PresentationAction<PlayerDetailFeature.Action>)

        @CasePathable
        enum View {
            case kickOffButtonTapped
            case replayButtonTapped
            case nextFixtureButtonTapped
            case tabSelected(State.Tab)
            case playerTapped(Player.ID)
        }
    }

    @Dependency(\.entropy) var entropy

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.kickOffButtonTapped):
                guard !state.currentWeekIsInTheTable else { return .none }
                if state.pending == nil {
                    guard state.weeks.indices.contains(state.weekIndex) else {
                        state.didFail = true
                        return .none
                    }
                    let seed = Matchweek.weekSeed(draw: entropy.nextSeed(), weekIndex: state.weekIndex)
                    guard let played = Matchweek.play(
                        fixtures: state.weeks[state.weekIndex],
                        clubs: state.clubs,
                        userClubID: state.userClubID,
                        seed: seed
                    ) else {
                        state.didFail = true
                        return .none
                    }
                    state.pending = played
                    state.didFail = false
                }
                if let pending = state.pending {
                    state.stats = nil
                    state.highlight = HighlightFeature.State(
                        match: pending.userMatch,
                        home: pending.home,
                        away: pending.away
                    )
                }
                return .none

            case .view(.replayButtonTapped):
                guard let pending = state.pending, state.currentWeekIsInTheTable else { return .none }
                state.stats = nil
                state.highlight = HighlightFeature.State(
                    match: pending.userMatch,
                    home: pending.home,
                    away: pending.away
                )
                return .none

            case .view(.nextFixtureButtonTapped):
                guard state.hasNextFixture else { return .none }
                state.weekIndex += 1
                state.pending = nil
                state.highlight = nil
                state.stats = nil
                state.player = nil
                state.didFail = false
                return .none

            case let .view(.tabSelected(tab)):
                state.tab = tab
                return .none

            case let .view(.playerTapped(id)):
                guard let player = state.userClub?.starters.first(where: { $0.id == id }) else { return .none }
                state.player = PlayerDetailFeature.State(player: player)
                return .none

            case .highlight(.presented(.delegate(.dismissed))):
                state.highlight = nil
                state.stats = nil
                state.commitPendingWeek()
                return .none

            case .highlight(.presented(.delegate(.showStats))):
                guard state.highlight?.phase == .fullTime, let pending = state.pending else { return .none }
                state.stats = MatchStatsFeature.State(
                    shots: pending.userMatch.shots,
                    homeShort: pending.home.shortName,
                    awayShort: pending.away.shortName
                )
                return .none

            case .highlight:
                return .none

            case .stats(.presented(.delegate(.dismissed))):
                state.highlight = nil
                state.stats = nil
                state.commitPendingWeek()
                return .none

            case .stats, .player:
                return .none
            }
        }
        .ifLet(\.$highlight, action: \.highlight) {
            HighlightFeature()
        }
        .ifLet(\.$stats, action: \.stats) {
            MatchStatsFeature()
        }
        .ifLet(\.$player, action: \.player) {
            PlayerDetailFeature()
        }
    }
}
