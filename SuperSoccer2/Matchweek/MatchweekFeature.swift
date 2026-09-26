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
        var totals: [String: LeagueLeaders.Counts]
        var playerClub: [String: String]
        /// Set when the last week is on the table. A later history screen reads this record.
        var record: SeasonRecord?
        var didFail: Bool
        var tab: Tab
        /// Skills the user has not spent yet. A week can add zero or several.
        var skillOffers: [SkillOffer]
        var skillChoices: [SkillChoice]
        var lineupRevision: Int
        var skillsChosen: Int
        @Presents var highlight: HighlightFeature.State?
        @Presents var stats: MatchStatsFeature.State?
        @Presents var leaders: LeadersFeature.State?
        @Presents var championship: ChampionshipFeature.State?
        @Presents var team: TeamFeature.State?
        @Presents var player: PlayerDetailFeature.State?
        @Presents var seasonAlert: AlertState<Action.SeasonAlert>?

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
            totals = [:]
            playerClub = [:]
            record = nil
            didFail = false
            tab = .club
            skillOffers = []
            skillChoices = WeekTuning.current.skillChoices
            lineupRevision = 0
            skillsChosen = 0
            highlight = nil
            stats = nil
            leaders = nil
            championship = nil
            team = nil
            player = nil
            seasonAlert = nil
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

        var playedHomeShort: String? {
            guard currentWeekIsInTheTable else { return nil }
            return pending?.home.shortName
        }

        var playedAwayShort: String? {
            guard currentWeekIsInTheTable else { return nil }
            return pending?.away.shortName
        }

        var playedHomeScore: Int? {
            guard currentWeekIsInTheTable else { return nil }
            return pending?.userMatch.homeScore
        }

        var playedAwayScore: Int? {
            guard currentWeekIsInTheTable else { return nil }
            return pending?.userMatch.awayScore
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

        var goalLeaders: [LeagueLeaders.Row] { ranked(\.goals) }
        var assistLeaders: [LeagueLeaders.Row] { ranked(\.assists) }
        var saveLeaders: [LeagueLeaders.Row] { ranked(\.saves) }

        fileprivate func squadPlayer(_ id: Player.ID) -> (club: Club, player: Player)? {
            for club in clubs {
                if let player = club.players.first(where: { $0.id == id }) {
                    return (club, player)
                }
            }
            return nil
        }

        fileprivate func leaders(for clubID: String, _ count: KeyPath<LeagueLeaders.Counts, Int>) -> [LeagueLeaders.Row] {
            ranked(count).filter { $0.clubID == clubID }
        }

        private func ranked(_ count: KeyPath<LeagueLeaders.Counts, Int>) -> [LeagueLeaders.Row] {
            let players = Dictionary(uniqueKeysWithValues: clubs.flatMap(\.players).map { ($0.id, $0) })
            let clubsByID = Dictionary(uniqueKeysWithValues: clubs.map { ($0.id, $0) })
            return totals.compactMap { playerID, counts -> LeagueLeaders.Row? in
                let value = counts[keyPath: count]
                guard value > 0, let player = players[playerID] else { return nil }
                let clubID = playerClub[playerID] ?? ""
                return LeagueLeaders.Row(
                    player: player,
                    clubID: clubID,
                    clubName: clubsByID[clubID]?.name ?? clubID,
                    count: value
                )
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                if lhs.player.fullName != rhs.player.fullName { return lhs.player.fullName < rhs.player.fullName }
                return lhs.player.id < rhs.player.id
            }
        }

        fileprivate mutating func commitPendingWeek(choosesUserSkills: Bool = false) {
            guard let pending, !currentWeekIsInTheTable else { return }
            standings = LeagueTable.applying(pending.scorelines, to: standings)
            totals = SeasonTotals.adding(pending.tallies, to: totals)
            for tally in pending.tallies where tally.goals + tally.assists + tally.saves > 0 {
                if playerClub[tally.playerID] == nil {
                    playerClub[tally.playerID] = tally.clubID
                }
            }
            let tuning = WeekTuning.current
            let settlement = WeekBetween.settle(
                clubs: clubs,
                scorelines: pending.scorelines,
                tallies: pending.tallies,
                userClubID: userClubID,
                seed: pending.userMatch.seed &+ 91,
                tuning: tuning
            )
            clubs = settlement.clubs
            for offer in settlement.offers {
                var copy = offer
                copy.id = "\(weekIndex)|\(offer.id)|\(skillOffers.count)"
                skillOffers.append(copy)
            }
            skillChoices = tuning.skillChoices
            if choosesUserSkills {
                var offers = skillOffers
                var squads = clubs
                WeekBetween.resolveAutomatically(&offers, clubs: &squads, tuning: tuning)
                skillOffers = offers
                clubs = squads
            }
            committedWeeks = weekIndex + 1
            if seasonIsOver {
                record = SeasonAwards.make(clubs: clubs, table: table, totals: totals)
            }
            if let teamID = team?.club.id, let club = clubs.first(where: { $0.id == teamID }) {
                team?.club = club
            }
            if let current = player?.player.id, let found = squadPlayer(current) {
                player = playerDetail(for: found.player, in: found.club)
            }
        }

        func playerDetail(for player: Player, in club: Club) -> PlayerDetailFeature.State {
            let manages = club.id == userClubID && player.isStarter && player.injury == nil
            return PlayerDetailFeature.State(
                player: player,
                clubName: club.name,
                canManage: manages,
                bestFit: manages ? WeekBetween.bestFit(replacing: player, in: club.players) : nil,
                alternatives: manages ? WeekBetween.alternatives(replacing: player, in: club.players) : []
            )
        }
    }

    enum Action {
        case view(View)
        case highlight(PresentationAction<HighlightFeature.Action>)
        case stats(PresentationAction<MatchStatsFeature.Action>)
        case leaders(PresentationAction<LeadersFeature.Action>)
        case championship(PresentationAction<ChampionshipFeature.Action>)
        case team(PresentationAction<TeamFeature.Action>)
        case player(PresentationAction<PlayerDetailFeature.Action>)
        case seasonAlert(PresentationAction<SeasonAlert>)

        @CasePathable
        enum View {
            case kickOffButtonTapped
            case simulateMatchButtonTapped
            case simulateSeasonButtonTapped
            case replayButtonTapped
            case nextFixtureButtonTapped
            case tabSelected(State.Tab)
            case leadersButtonTapped
            case championshipButtonTapped
            case teamButtonTapped(String)
            case playerTapped(Player.ID)
            case restStarter(Player.ID)
            case skillStatTapped(String, PlayerStat)
        }

        @CasePathable
        enum SeasonAlert: Equatable {
            case confirm
        }
    }

    @Dependency(\.entropy) var entropy

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.kickOffButtonTapped):
                guard !state.currentWeekIsInTheTable else { return .none }
                guard ensurePending(&state), let pending = state.pending else { return .none }
                state.stats = nil
                state.highlight = HighlightFeature.State(
                    match: pending.userMatch,
                    home: pending.home,
                    away: pending.away
                )
                return .none

            case .view(.simulateMatchButtonTapped):
                guard !state.currentWeekIsInTheTable else { return .none }
                guard ensurePending(&state) else { return .none }
                state.highlight = nil
                state.stats = nil
                state.commitPendingWeek()
                return .none

            case .view(.simulateSeasonButtonTapped):
                guard !state.seasonIsOver else { return .none }
                state.seasonAlert = AlertState {
                    TextState("Simulate the rest of the season?")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                    ButtonState(role: .destructive, action: .confirm) {
                        TextState("Simulate")
                    }
                } message: {
                    TextState("Every remaining week is played.")
                }
                return .none

            case .seasonAlert(.presented(.confirm)):
                simulateRemainingSeason(&state)
                return .none

            case .seasonAlert:
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
                state.leaders = nil
                state.championship = nil
                state.team = nil
                state.player = nil
                state.didFail = false
                return .none

            case let .view(.tabSelected(tab)):
                state.tab = tab
                return .none

            case .view(.leadersButtonTapped):
                state.leaders = LeadersFeature.State(
                    goals: state.goalLeaders,
                    assists: state.assistLeaders,
                    saves: state.saveLeaders,
                    userClubID: state.userClubID
                )
                return .none

            case .view(.championshipButtonTapped):
                guard state.seasonIsOver, let record = state.record,
                      let champion = state.clubs.first(where: { $0.id == record.championClubID })
                else { return .none }
                state.championship = ChampionshipFeature.State(
                    record: record,
                    nickname: champion.nickname,
                    kit: champion.kit,
                    goals: state.leaders(for: champion.id, \.goals),
                    assists: state.leaders(for: champion.id, \.assists),
                    saves: state.leaders(for: champion.id, \.saves),
                    userClubID: state.userClubID
                )
                return .none

            case let .view(.teamButtonTapped(id)):
                guard let club = state.clubs.first(where: { $0.id == id }) else { return .none }
                let standing = state.standings.first { $0.clubID == id }
                state.team = TeamFeature.State(
                    club: club,
                    played: standing?.played ?? 0,
                    points: standing?.points ?? 0,
                    goalDifference: standing?.goalDifference ?? 0,
                    canManage: id == state.userClubID
                )
                return .none

            case let .view(.playerTapped(id)):
                guard let found = state.squadPlayer(id) else { return .none }
                state.player = state.playerDetail(for: found.player, in: found.club)
                return .none

            case let .view(.restStarter(id)):
                rest(id, in: &state)
                return .none

            case let .view(.skillStatTapped(offerID, stat)):
                var offers = state.skillOffers
                var squads = state.clubs
                guard WeekBetween.apply(stat, offerID: offerID, offers: &offers, clubs: &squads) else {
                    return .none
                }
                state.skillOffers = offers
                state.clubs = squads
                state.skillsChosen += 1
                refreshPresented(&state)
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

            case let .team(.presented(.delegate(.replace(outgoing, incoming)))):
                replace(outgoing, with: incoming, in: &state)
                return .none

            case let .player(.presented(.delegate(.replace(incoming)))):
                guard let outgoing = state.player?.player.id else { return .none }
                replace(outgoing, with: incoming, in: &state)
                return .none

            case .stats, .leaders, .championship, .team, .player:
                return .none
            }
        }
        .ifLet(\.$highlight, action: \.highlight) {
            HighlightFeature()
        }
        .ifLet(\.$stats, action: \.stats) {
            MatchStatsFeature()
        }
        .ifLet(\.$leaders, action: \.leaders) {
            LeadersFeature()
        }
        .ifLet(\.$championship, action: \.championship) {
            ChampionshipFeature()
        }
        .ifLet(\.$team, action: \.team) {
            TeamFeature()
        }
        .ifLet(\.$player, action: \.player) {
            PlayerDetailFeature()
        }
        .ifLet(\.$seasonAlert, action: \.seasonAlert)
    }

    private func ensurePending(_ state: inout State) -> Bool {
        if state.pending != nil { return true }
        guard state.weeks.indices.contains(state.weekIndex) else {
            state.didFail = true
            return false
        }
        let seed = Matchweek.weekSeed(draw: entropy.nextSeed(), weekIndex: state.weekIndex)
        guard let played = Matchweek.play(
            fixtures: state.weeks[state.weekIndex],
            clubs: state.clubs,
            userClubID: state.userClubID,
            seed: seed
        ) else {
            state.didFail = true
            return false
        }
        state.pending = played
        state.didFail = false
        return true
    }

    private func simulateRemainingSeason(_ state: inout State) {
        state.highlight = nil
        state.stats = nil
        state.leaders = nil
        state.championship = nil
        state.team = nil
        state.player = nil
        state.seasonAlert = nil
        while !state.seasonIsOver {
            if state.currentWeekIsInTheTable {
                guard state.hasNextFixture else { return }
                state.weekIndex += 1
                state.pending = nil
                state.didFail = false
            }
            guard ensurePending(&state) else { return }
            state.commitPendingWeek(choosesUserSkills: true)
        }
        refreshPresented(&state)
    }

    private func rest(_ id: Player.ID, in state: inout State) {
        guard let club = state.clubs.first(where: { $0.id == state.userClubID }),
              let starter = club.players.first(where: { $0.id == id }),
              let incoming = WeekBetween.bestFit(replacing: starter, in: club.players)
        else { return }
        replace(id, with: incoming.id, in: &state)
    }

    private func replace(_ outgoingID: Player.ID, with incomingID: Player.ID, in state: inout State) {
        guard let index = state.clubs.firstIndex(where: { $0.id == state.userClubID }),
              let updated = WeekBetween.replace(outgoingID, with: incomingID, in: state.clubs[index])
        else { return }
        state.clubs[index] = updated
        state.lineupRevision += 1
        state.player = nil
        state.team?.player = nil
        refreshPresented(&state)
    }

    private func refreshPresented(_ state: inout State) {
        if let teamID = state.team?.club.id,
           let club = state.clubs.first(where: { $0.id == teamID }) {
            state.team?.club = club
        }
    }
}
