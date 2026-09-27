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
        /// Week the Week screen is showing. Nil follows the season week, so the screen opens on the current week.
        var browsedWeekIndex: Int?
        /// Scorelines for weeks already on the table, in week order.
        var playedWeeks: [[Matchweek.Scoreline]]
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
        /// Where to go once every open skill has a stat.
        var skillFollowUp: SkillFollowUp?
        @Presents var skillChoice: SkillChoiceFeature.State?
        @Presents var highlight: HighlightFeature.State?
        @Presents var stats: MatchStatsFeature.State?
        @Presents var leaders: LeadersFeature.State?
        @Presents var championship: ChampionshipFeature.State?
        @Presents var team: TeamFeature.State?
        @Presents var player: PlayerDetailFeature.State?
        /// Rest or Play opened from the Club tab. The table’s club screen keeps its own.
        @Presents var substitution: SubstitutionFeature.State?
        @Presents var seasonAlert: AlertState<Action.SeasonAlert>?

        enum Tab: Equatable, Hashable, Sendable, CaseIterable {
            case club
            case table
            case week
            case match
        }

        enum SkillFollowUp: Equatable, Sendable {
            case nextWeek
            case championship
        }

        struct WeekLine: Equatable, Identifiable, Sendable {
            var homeID: String
            var awayID: String
            var homeScore: Int?
            var awayScore: Int?

            var id: String { "\(homeID)-\(awayID)" }
        }

        struct ScorerLine: Equatable, Identifiable, Sendable {
            var playerID: Player.ID
            var name: String
            var goals: Int

            var id: String { playerID }

            /// One goal is the name. Repeats carry a count: "Marvin Dave (2)".
            var label: String {
                goals > 1 ? "\(name) (\(goals))" : name
            }
        }

        struct ScorerGroup: Equatable, Identifiable, Sendable {
            var clubID: String
            var clubName: String
            var lines: [ScorerLine]

            var id: String { clubID }
        }

        init(userClubID: String, season: LeagueDraft.Season) {
            self.userClubID = userClubID
            clubs = season.clubs
            weeks = LeagueDraft.weeks(in: season.fixtures)
            weekIndex = 0
            browsedWeekIndex = nil
            playedWeeks = []
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

        var weekNumber: Int { weekIndex + 1 }

        var nextWeekNumber: Int { weekNumber + 1 }

        /// The week on the Week screen. Paging does not move the season.
        var shownWeekIndex: Int {
            let chosen = browsedWeekIndex ?? weekIndex
            guard weeks.indices.contains(chosen) else { return weekIndex }
            return chosen
        }

        var browsedWeekNumber: Int { shownWeekIndex + 1 }

        var weekCount: Int { weeks.count }

        var canBrowseEarlierWeek: Bool { shownWeekIndex > 0 }

        var canBrowseLaterWeek: Bool { shownWeekIndex + 1 < weeks.count }

        var browsingTheCurrentWeek: Bool { shownWeekIndex == weekIndex }

        var browsedWeekHasResults: Bool { storedScorelines(for: shownWeekIndex) != nil }

        private func storedScorelines(for index: Int) -> [Matchweek.Scoreline]? {
            if playedWeeks.indices.contains(index), !playedWeeks[index].isEmpty {
                return playedWeeks[index]
            }
            if index == weekIndex, currentWeekIsInTheTable, let lines = pending?.scorelines, !lines.isEmpty {
                return lines
            }
            return nil
        }

        var advanceWeekTitle: String { "Advance to week \(nextWeekNumber)" }

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

        /// Heading for the post-match scorers. Club headers and player rows are this match's goals.
        var matchScorersTitle: String { "Goals" }

        /// This match's scorers. The user's club, then the opponent. Empty before the week is on the table.
        var matchScorers: [ScorerGroup] {
            guard currentWeekIsInTheTable, let pending, let user = userClub, let opponent else { return [] }
            return [
                ScorerGroup(
                    clubID: user.id,
                    clubName: user.name,
                    lines: scorerLines(in: pending.userMatch.shots, isHome: userIsHome)
                ),
                ScorerGroup(
                    clubID: opponent.id,
                    clubName: opponent.name,
                    lines: scorerLines(in: pending.userMatch.shots, isHome: !userIsHome)
                )
            ]
        }

        private func scorerLines(in shots: [Shot], isHome: Bool) -> [ScorerLine] {
            let goals = shots.enumerated().filter { $0.element.isHome == isHome && $0.element.result == .goal }
            let ordered = goals.sorted { lhs, rhs in
                if lhs.element.minute != rhs.element.minute {
                    return lhs.element.minute < rhs.element.minute
                }
                return lhs.offset < rhs.offset
            }
            var order: [Player.ID] = []
            var names: [Player.ID: String] = [:]
            var counts: [Player.ID: Int] = [:]
            for shot in ordered.map(\.element) {
                let id = shot.shooter.id
                if counts[id] == nil {
                    order.append(id)
                    names[id] = shot.shooter.fullName
                    counts[id] = 1
                } else {
                    counts[id, default: 0] += 1
                }
            }
            return order.map { id in
                ScorerLine(playerID: id, name: names[id] ?? "", goals: counts[id] ?? 0)
            }
        }

        var weekLines: [WeekLine] {
            guard weeks.indices.contains(shownWeekIndex) else { return [] }
            let played = storedScorelines(for: shownWeekIndex) ?? []
            let scores = Dictionary(uniqueKeysWithValues: played.map { ("\($0.homeID)-\($0.awayID)", $0) })
            return weeks[shownWeekIndex].enumerated().map { offset, fixture in
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

        @discardableResult
        fileprivate mutating func commitPendingWeek(choosesUserSkills: Bool = false) -> Bool {
            guard let pending, !currentWeekIsInTheTable else { return false }
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
            if playedWeeks.count == weekIndex {
                playedWeeks.append(pending.scorelines)
            }
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
            return true
        }

        /// Shows the next unspent skill. The step count stays put as offers are spent.
        @discardableResult
        mutating func presentNextSkill(contextLine: String) -> Bool {
            guard let offer = skillOffers.first, let found = squadPlayer(offer.playerID) else { return false }
            let stepCount = skillChoice?.stepCount ?? skillOffers.count
            let step = (skillChoice?.step ?? 0) + 1
            let line = skillChoice?.contextLine ?? contextLine
            skillChoice = SkillChoiceFeature.State(
                offerID: offer.id,
                player: found.player,
                choices: skillChoices,
                step: step,
                stepCount: stepCount,
                contextLine: line
            )
            return true
        }

        func playerDetail(for player: Player, in club: Club) -> PlayerDetailFeature.State {
            PlayerDetailFeature.State(player: player, clubName: club.name, clubID: club.id)
        }

        func teamScreen(for club: Club) -> TeamFeature.State {
            let standing = standings.first { $0.clubID == club.id }
            let played = standing?.played ?? 0
            return TeamFeature.State(
                club: club,
                won: standing?.won ?? 0,
                lost: standing?.lost ?? 0,
                drawn: standing?.drawn ?? 0,
                points: standing?.points ?? 0,
                goalDifference: standing?.goalDifference ?? 0,
                place: played > 0 ? places[club.id] : nil,
                canManage: club.id == userClubID
            )
        }
    }

    enum Action {
        case view(View)
        case delegate(Delegate)
        case highlight(PresentationAction<HighlightFeature.Action>)
        case stats(PresentationAction<MatchStatsFeature.Action>)
        case leaders(PresentationAction<LeadersFeature.Action>)
        case championship(PresentationAction<ChampionshipFeature.Action>)
        case team(PresentationAction<TeamFeature.Action>)
        case player(PresentationAction<PlayerDetailFeature.Action>)
        case substitution(PresentationAction<SubstitutionFeature.Action>)
        case skillChoice(PresentationAction<SkillChoiceFeature.Action>)
        case seasonAlert(PresentationAction<SeasonAlert>)

        @CasePathable
        enum View {
            case kickOffButtonTapped
            case simulateMatchButtonTapped
            case simulateSeasonButtonTapped
            case replayButtonTapped
            case nextFixtureButtonTapped
            case previousWeekButtonTapped
            case nextWeekButtonTapped
            case tabSelected(State.Tab)
            case menuButtonTapped
            case leadersButtonTapped
            case championshipButtonTapped
            case teamButtonTapped(String)
            case playerTapped(Player.ID)
            case restStarter(Player.ID)
            case playBench(Player.ID)
        }

        @CasePathable
        enum Delegate {
            case openMenu
        }

        @CasePathable
        enum SeasonAlert: Equatable {
            case confirm
        }
    }

    @Dependency(\.entropy) var entropy
    @Dependency(\.careerStore) var careerStore

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
                guard state.commitPendingWeek() else { return .none }
                return save(state)

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
                return save(state)

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
                guard state.hasNextFixture, state.skillChoice == nil else { return .none }
                if beginSkills(&state, then: .nextWeek) { return .none }
                advanceWeek(&state)
                return save(state)

            case .view(.previousWeekButtonTapped):
                guard state.canBrowseEarlierWeek else { return .none }
                state.browsedWeekIndex = state.shownWeekIndex - 1
                return .none

            case .view(.nextWeekButtonTapped):
                guard state.canBrowseLaterWeek else { return .none }
                state.browsedWeekIndex = state.shownWeekIndex + 1
                return .none

            case let .view(.tabSelected(tab)):
                state.tab = tab
                return .none

            case .view(.menuButtonTapped):
                return .send(.delegate(.openMenu))

            case .delegate:
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
                guard state.seasonIsOver, state.record != nil, state.skillChoice == nil else { return .none }
                if beginSkills(&state, then: .championship) { return .none }
                openChampionship(&state)
                return .none

            case let .view(.teamButtonTapped(id)):
                guard let club = state.clubs.first(where: { $0.id == id }) else { return .none }
                state.team = state.teamScreen(for: club)
                return .none

            case let .view(.playerTapped(id)):
                guard let found = state.squadPlayer(id) else { return .none }
                state.player = state.playerDetail(for: found.player, in: found.club)
                return .none

            case let .view(.restStarter(id)):
                presentLineup(.rest, playerID: id, in: &state)
                return .none

            case let .view(.playBench(id)):
                presentLineup(.play, playerID: id, in: &state)
                return .none

            case let .substitution(.presented(.delegate(.chosen(id)))):
                guard let swap = state.substitution?.swap(chosenID: id) else {
                    state.substitution = nil
                    return .none
                }
                state.substitution = nil
                guard replace(swap.outgoing, with: swap.incoming, in: &state) else { return .none }
                return save(state)

            case .substitution(.presented(.delegate(.cancelled))), .substitution(.dismiss):
                state.substitution = nil
                return .none

            case let .skillChoice(.presented(.delegate(.chose(stat)))):
                guard let offerID = state.skillChoice?.offerID else { return .none }
                var offers = state.skillOffers
                var squads = state.clubs
                guard WeekBetween.apply(stat, offerID: offerID, offers: &offers, clubs: &squads) else {
                    return .none
                }
                state.skillOffers = offers
                state.clubs = squads
                state.skillsChosen += 1
                refreshPresented(&state)
                if state.presentNextSkill(contextLine: state.skillChoice?.contextLine ?? "") {
                    return save(state)
                }
                let followUp = state.skillFollowUp
                state.skillChoice = nil
                state.skillFollowUp = nil
                switch followUp {
                case .nextWeek:
                    advanceWeek(&state)
                case .championship:
                    openChampionship(&state)
                case nil:
                    break
                }
                return save(state)

            case .skillChoice(.dismiss):
                state.skillFollowUp = nil
                return .none

            case .skillChoice:
                return .none

            case .highlight(.presented(.delegate(.dismissed))):
                state.highlight = nil
                state.stats = nil
                guard state.commitPendingWeek() else { return .none }
                return save(state)

            case .highlight(.presented(.delegate(.showStats))):
                guard state.highlight?.phase == .fullTime, let pending = state.pending else { return .none }
                state.stats = MatchStatsFeature.State(
                    shots: pending.userMatch.shots,
                    homeShort: pending.home.shortName,
                    awayShort: pending.away.shortName,
                    homeName: pending.home.name,
                    awayName: pending.away.name,
                    homeID: pending.home.id,
                    awayID: pending.away.id
                )
                return .none

            case .highlight:
                return .none

            case .stats(.presented(.delegate(.dismissed))):
                state.highlight = nil
                state.stats = nil
                guard state.commitPendingWeek() else { return .none }
                return save(state)

            case let .team(.presented(.delegate(.replace(outgoing, incoming)))):
                guard replace(outgoing, with: incoming, in: &state) else { return .none }
                return save(state)

            case .stats, .leaders, .championship, .team, .player, .substitution:
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
        .ifLet(\.$substitution, action: \.substitution) {
            SubstitutionFeature()
        }
        .ifLet(\.$skillChoice, action: \.skillChoice) {
            SkillChoiceFeature()
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
        state.substitution = nil
        state.skillChoice = nil
        state.skillFollowUp = nil
        state.seasonAlert = nil
        state.browsedWeekIndex = nil
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

    private func beginSkills(_ state: inout State, then followUp: State.SkillFollowUp) -> Bool {
        guard state.skillChoice == nil, state.skillOffers.isEmpty == false else { return false }
        let line = switch followUp {
        case .nextWeek: "Before the next week"
        case .championship: "Before the season ends"
        }
        state.skillFollowUp = followUp
        guard state.presentNextSkill(contextLine: line) else {
            state.skillFollowUp = nil
            return false
        }
        return true
    }

    private func advanceWeek(_ state: inout State) {
        state.weekIndex += 1
        state.browsedWeekIndex = nil
        state.pending = nil
        state.highlight = nil
        state.stats = nil
        state.leaders = nil
        state.championship = nil
        state.team = nil
        state.player = nil
        state.substitution = nil
        state.didFail = false
    }

    private func openChampionship(_ state: inout State) {
        guard state.seasonIsOver, let record = state.record,
              let champion = state.clubs.first(where: { $0.id == record.championClubID })
        else { return }
        state.championship = ChampionshipFeature.State(
            record: record,
            nickname: champion.nickname,
            kit: champion.kit,
            goals: state.leaders(for: champion.id, \.goals),
            assists: state.leaders(for: champion.id, \.assists),
            saves: state.leaders(for: champion.id, \.saves),
            userClubID: state.userClubID
        )
    }

    private func presentLineup(
        _ kind: SubstitutionFeature.State.Kind,
        playerID: Player.ID,
        in state: inout State
    ) {
        guard state.substitution == nil,
              let club = state.userClub,
              let player = club.players.first(where: { $0.id == playerID }),
              let prompt = SubstitutionFeature.State.make(kind, player: player, in: club.players)
        else { return }
        state.substitution = prompt
    }

    private func replace(_ outgoingID: Player.ID, with incomingID: Player.ID, in state: inout State) -> Bool {
        guard let index = state.clubs.firstIndex(where: { $0.id == state.userClubID }),
              let updated = WeekBetween.replace(outgoingID, with: incomingID, in: state.clubs[index])
        else { return false }
        state.clubs[index] = updated
        state.lineupRevision += 1
        state.player = nil
        state.substitution = nil
        state.team?.player = nil
        state.team?.substitution = nil
        refreshPresented(&state)
        return true
    }

    private func save(_ state: State) -> Effect<Action> {
        let career = Career(matchweek: state)
        return .run { [careerStore] _ in
            await careerStore.save(career)
        }
    }

    private func refreshPresented(_ state: inout State) {
        guard let teamID = state.team?.club.id,
              let club = state.clubs.first(where: { $0.id == teamID })
        else { return }
        let screen = state.teamScreen(for: club)
        state.team?.club = screen.club
        state.team?.won = screen.won
        state.team?.lost = screen.lost
        state.team?.drawn = screen.drawn
        state.team?.points = screen.points
        state.team?.goalDifference = screen.goalDifference
        state.team?.place = screen.place
    }
}
