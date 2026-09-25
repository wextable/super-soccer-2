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
        @Presents var highlight: HighlightFeature.State?

        init(userClubID: String, season: LeagueDraft.Season) {
            self.userClubID = userClubID
            clubs = season.clubs
            weeks = LeagueDraft.weeks(in: season.fixtures)
            weekIndex = 0
            standings = LeagueTable.zeros(clubIDs: season.clubs.map(\.id))
            committedWeeks = 0
            pending = nil
            didFail = false
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
    }

    enum Action {
        case view(View)
        case highlight(PresentationAction<HighlightFeature.Action>)

        @CasePathable
        enum View {
            case kickOffButtonTapped
            case replayButtonTapped
            case nextFixtureButtonTapped
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
                    state.highlight = HighlightFeature.State(
                        match: pending.userMatch,
                        home: pending.home,
                        away: pending.away
                    )
                }
                return .none

            case .view(.replayButtonTapped):
                guard let pending = state.pending, state.currentWeekIsInTheTable else { return .none }
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
                state.didFail = false
                return .none

            case .highlight(.presented(.delegate(.dismissed))):
                state.highlight = nil
                guard let pending = state.pending, !state.currentWeekIsInTheTable else { return .none }
                state.standings = LeagueTable.applying(pending.scorelines, to: state.standings)
                state.committedWeeks = state.weekIndex + 1
                return .none

            case .highlight:
                return .none
            }
        }
        .ifLet(\.$highlight, action: \.highlight) {
            HighlightFeature()
        }
    }
}
