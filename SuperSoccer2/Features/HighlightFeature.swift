import ComposableArchitecture
import Foundation

@Reducer
struct HighlightFeature {
    /// Score on the board before the current shot is resolved.
    static let beatDuration: Duration = .milliseconds(800)
    /// How long the resolved shot stays up so the sentence can be read.
    static let lineDuration: Duration = .milliseconds(2400)

    @ObservableState
    struct State: Equatable {
        var homeShort: String
        var awayShort: String
        var homeName: String
        var awayName: String
        var homeScore: Int
        var awayScore: Int
        var finalHomeScore: Int
        var finalAwayScore: Int
        var shots: [Shot]
        var index: Int
        var phase: Phase
        var minute: Int
        var commentary: String
        var showsPasser: Bool
        var attackingIsHome: Bool
        var homeKit: Kit
        var awayKit: Kit
        var result: ShotResult
        var ballProgress: Double
        var sentenceVisible: Bool
        var reduceMotion: Bool
        var hasAppeared: Bool

        enum Phase: Equatable, Sendable {
            case incoming
            case shown
            case fullTime
        }

        var minuteText: String {
            phase == .fullTime ? "FT" : "\(minute)'"
        }

        init(match: MatchResult, home: Club, away: Club) {
            homeShort = home.shortName
            awayShort = away.shortName
            homeName = home.name
            awayName = away.name
            finalHomeScore = match.homeScore
            finalAwayScore = match.awayScore
            shots = Self.inMinuteOrder(match.shots)
            index = 0
            phase = .incoming
            minute = 0
            commentary = ""
            showsPasser = false
            attackingIsHome = true
            homeKit = home.kit
            awayKit = away.kit
            result = .miss
            ballProgress = 0
            sentenceVisible = false
            reduceMotion = false
            hasAppeared = false
            homeScore = 0
            awayScore = 0
            if shots.isEmpty {
                showFullTime()
            } else {
                showIncoming()
            }
        }

        fileprivate static func inMinuteOrder(_ shots: [Shot]) -> [Shot] {
            shots.enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.minute != rhs.element.minute {
                        return lhs.element.minute < rhs.element.minute
                    }
                    return lhs.offset < rhs.offset
                }
                .map(\.element)
        }

        fileprivate mutating func showIncoming() {
            let shot = shots[index]
            phase = .incoming
            minute = shot.minute
            commentary = line(for: shot)
            showsPasser = shot.passer != nil
            attackingIsHome = shot.isHome
            result = shot.result
            let score = goals(endingAt: index)
            homeScore = score.home
            awayScore = score.away
            ballProgress = 0
            sentenceVisible = false
        }

        fileprivate mutating func revealCurrent() {
            let shot = shots[index]
            phase = .shown
            minute = shot.minute
            commentary = line(for: shot)
            showsPasser = shot.passer != nil
            attackingIsHome = shot.isHome
            result = shot.result
            let score = goals(endingAt: index + 1)
            homeScore = score.home
            awayScore = score.away
            ballProgress = 1
            sentenceVisible = true
        }

        /// Reduce motion skips the hold before a shot and lands on its result.
        fileprivate mutating func showNextResult() {
            switch phase {
            case .incoming:
                revealCurrent()
            case .shown:
                if index + 1 < shots.count {
                    index += 1
                    revealCurrent()
                } else {
                    showFullTime()
                }
            case .fullTime:
                break
            }
        }

        fileprivate mutating func showFullTime() {
            phase = .fullTime
            homeScore = finalHomeScore
            awayScore = finalAwayScore
            commentary = "Full time."
            sentenceVisible = true
            ballProgress = 1
            showsPasser = false
        }

        /// The same frame the clock reaches after the last shot.
        fileprivate mutating func finishReel() {
            if let last = shots.indices.last {
                index = last
                let shot = shots[last]
                minute = shot.minute
                attackingIsHome = shot.isHome
                result = shot.result
            }
            showFullTime()
        }

        private func line(for shot: Shot) -> String {
            Commentary.line(
                shot: shot,
                attackingClub: shot.isHome ? homeName : awayName,
                defendingClub: shot.isHome ? awayName : homeName
            )
        }

        private func goals(endingAt end: Int) -> (home: Int, away: Int) {
            var home = 0
            var away = 0
            for shot in shots.prefix(end) where shot.result == .goal {
                if shot.isHome {
                    home += 1
                } else {
                    away += 1
                }
            }
            return (home, away)
        }
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case onAppear(reduceMotion: Bool)
            case advance
            case skipButtonTapped
            case backButtonTapped
        }

        @CasePathable
        enum Delegate {
            case dismissed
        }
    }

    enum CancelID { case beat }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .view(.onAppear(reduceMotion)):
                guard !state.hasAppeared else { return .none }
                state.hasAppeared = true
                state.reduceMotion = reduceMotion
                guard state.phase != .fullTime else { return .none }
                if reduceMotion {
                    state.revealCurrent()
                    return .none
                }
                return scheduleBeat(for: state.phase)

            case .view(.advance):
                guard state.phase != .fullTime else { return .none }
                if state.reduceMotion {
                    state.showNextResult()
                    return .none
                }
                switch state.phase {
                case .incoming:
                    state.revealCurrent()
                    return scheduleBeat(for: state.phase)
                case .shown:
                    if state.index + 1 < state.shots.count {
                        state.index += 1
                        state.showIncoming()
                        return scheduleBeat(for: state.phase)
                    }
                    state.showFullTime()
                    return .none
                case .fullTime:
                    return .none
                }

            case .view(.skipButtonTapped):
                guard state.phase != .fullTime else { return .none }
                state.finishReel()
                return .cancel(id: CancelID.beat)

            case .view(.backButtonTapped):
                return .merge(
                    .cancel(id: CancelID.beat),
                    .send(.delegate(.dismissed))
                )

            case .delegate:
                return .none
            }
        }
    }

    private func scheduleBeat(for phase: State.Phase) -> Effect<Action> {
        let duration = phase == .shown ? Self.lineDuration : Self.beatDuration
        return .run { send in
            do {
                try await clock.sleep(for: duration)
                await send(.view(.advance))
            } catch is CancellationError {
                return
            }
        }
        .cancellable(id: CancelID.beat, cancelInFlight: true)
    }
}
