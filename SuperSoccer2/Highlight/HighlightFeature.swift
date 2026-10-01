import ComposableArchitecture
import Foundation

@Reducer
struct HighlightFeature {
    /// How long a shot sits before the move starts.
    static let beatDuration: Duration = .milliseconds(800)
    /// How long the resolved shot stays up so the sentence can be read.
    static let lineDuration: Duration = .milliseconds(2400)

    @ObservableState
    struct State: Equatable {
        var homeID: String
        var awayID: String
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
        var matchSeed: UInt64
        var script: HighlightScript?
        var attackingEnd: PitchEnd
        /// Increments when the attacked goal changes. The pitch swaps ends in place.
        var cameraFlip: Int
        /// Set once the half-time pause has been passed. The second half does not play the first again.
        var halfTimePassed: Bool

        enum Phase: Equatable, Sendable {
            case incoming
            case shown
            case halfTime
            case fullTime
        }

        enum Move: Equatable, Sendable {
            case shot
            case halfTime
            case fullTime
            case waiting
        }

        var minuteText: String {
            switch phase {
            case .fullTime:
                "FT"
            case .halfTime:
                "HT"
            case .incoming, .shown:
                "\(minute)'"
            }
        }

        var nextControlTitle: String {
            guard phase == .shown else { return "Next shot" }
            let upcoming = index + 1 < shots.count ? shots[index + 1] : nil
            if !halfTimePassed, upcoming == nil || (upcoming?.minute ?? 0) > HighlightScript.halfMinute {
                return "Half time"
            }
            if upcoming == nil {
                return "Full time"
            }
            return "Next shot"
        }

        init(match: MatchResult, home: Club, away: Club) {
            homeID = home.id
            awayID = away.id
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
            matchSeed = match.seed
            script = nil
            attackingEnd = .north
            cameraFlip = 0
            halfTimePassed = false
            homeScore = 0
            awayScore = 0
            if shots.isEmpty {
                showFullTime()
            } else if shots[0].minute > HighlightScript.halfMinute {
                showHalfTime()
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
            present(shots[index])
            phase = .incoming
            let score = goals(endingAt: index)
            homeScore = score.home
            awayScore = score.away
            ballProgress = 0
            sentenceVisible = false
        }

        fileprivate mutating func revealCurrent() {
            present(shots[index])
            phase = .shown
            let score = goals(endingAt: index + 1)
            homeScore = score.home
            awayScore = score.away
            ballProgress = 1
            sentenceVisible = true
        }

        /// Reduce motion skips the hold before a shot and lands on its result.
        fileprivate mutating func showNextResult() -> Move {
            switch phase {
            case .incoming:
                revealCurrent()
                return .shot
            case .shown:
                return moveOn(revealing: true)
            case .halfTime, .fullTime:
                return .waiting
            }
        }

        fileprivate mutating func moveOn(revealing: Bool) -> Move {
            if index + 1 < shots.count {
                let upcoming = shots[index + 1]
                if !halfTimePassed, upcoming.minute > HighlightScript.halfMinute {
                    showHalfTime()
                    return .halfTime
                }
                index += 1
                if revealing {
                    revealCurrent()
                } else {
                    showIncoming()
                }
                return .shot
            }
            if !halfTimePassed {
                showHalfTime()
                return .halfTime
            }
            showFullTime()
            return .fullTime
        }

        fileprivate mutating func showHalfTime() {
            phase = .halfTime
            commentary = "Half time."
            sentenceVisible = true
            showsPasser = false
            ballProgress = 1
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
            halfTimePassed = true
            if let last = shots.indices.last {
                index = last
                present(shots[last])
            }
            showFullTime()
        }

        /// Begins the second half at its first shot. Shots already shown stay shown.
        fileprivate mutating func beginSecondHalf() -> Move {
            halfTimePassed = true
            guard let next = shots.indices.first(where: { shots[$0].minute > HighlightScript.halfMinute }) else {
                showFullTime()
                return .fullTime
            }
            index = next
            if reduceMotion {
                revealCurrent()
            } else {
                showIncoming()
            }
            return .shot
        }

        private mutating func present(_ shot: Shot) {
            minute = shot.minute
            commentary = line(for: shot)
            showsPasser = shot.passer != nil
            attackingIsHome = shot.isHome
            result = shot.result
            let next = HighlightScript.make(shot: shot, matchSeed: matchSeed)
            if let previous = script?.attackingEnd, previous != next.attackingEnd {
                cameraFlip += 1
            }
            script = next
            attackingEnd = next.attackingEnd
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
            case statsButtonTapped
            case backButtonTapped
            case secondHalfStarted
        }

        @CasePathable
        enum Delegate {
            case dismissed
            case showStats
            case showHalfTime
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
                if state.phase == .halfTime {
                    return .send(.delegate(.showHalfTime))
                }
                guard state.phase != .fullTime else { return .none }
                if reduceMotion {
                    state.revealCurrent()
                    return .none
                }
                return scheduleBeat(for: state.phase)

            case .view(.advance):
                guard state.phase != .fullTime, state.phase != .halfTime else { return .none }
                if state.reduceMotion {
                    let move = state.showNextResult()
                    return effect(for: move, state: state)
                }
                switch state.phase {
                case .incoming:
                    state.revealCurrent()
                    return scheduleBeat(for: state.phase)
                case .shown:
                    let move = state.moveOn(revealing: false)
                    return effect(for: move, state: state)
                case .halfTime, .fullTime:
                    return .none
                }

            case .view(.skipButtonTapped):
                guard state.phase != .fullTime else { return .none }
                state.finishReel()
                return .cancel(id: CancelID.beat)

            case .view(.statsButtonTapped):
                guard state.phase == .fullTime else { return .none }
                return .merge(
                    .cancel(id: CancelID.beat),
                    .send(.delegate(.showStats))
                )

            case .view(.backButtonTapped):
                return .merge(
                    .cancel(id: CancelID.beat),
                    .send(.delegate(.dismissed))
                )

            case .view(.secondHalfStarted):
                guard state.phase == .halfTime else { return .none }
                let move = state.beginSecondHalf()
                return effect(for: move, state: state)

            case .delegate:
                return .none
            }
        }
    }

    private func effect(for move: State.Move, state: State) -> Effect<Action> {
        switch move {
        case .halfTime:
            return .merge(
                .cancel(id: CancelID.beat),
                .send(.delegate(.showHalfTime))
            )
        case .shot:
            guard !state.reduceMotion, state.phase == .incoming else { return .none }
            return scheduleBeat(for: .incoming)
        case .fullTime, .waiting:
            return .cancel(id: CancelID.beat)
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
