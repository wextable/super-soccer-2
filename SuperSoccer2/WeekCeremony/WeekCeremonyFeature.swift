import ComposableArchitecture
import Foundation

/// Injuries and level-ups after the match, then returns before the next week.
/// One list. A later notice is another case.
@Reducer
struct WeekCeremonyFeature {
    @ObservableState
    struct State: Equatable {
        var header: String
        var notices: [Notice]
        /// The notice on screen. The counter is this position in `notices`.
        var index: Int
        /// Where the matchweek goes when the after-match walk finishes. Nil for the return walk.
        var followUp: FollowUp?
        @Presents var injury: InjuryNoticeFeature.State?
        @Presents var levelUp: SkillChoiceFeature.State?
        @Presents var returnNotice: ReturnNoticeFeature.State?

        var step: Int { index + 1 }

        var stepCount: Int { notices.count }

        init(header: String, notices: [Notice], followUp: FollowUp?) {
            self.header = header
            self.notices = notices
            self.index = 0
            self.followUp = followUp
            injury = nil
            levelUp = nil
            returnNotice = nil
            presentCurrent()
        }

        mutating func presentCurrent() {
            guard notices.indices.contains(index) else { return }
            switch notices[index] {
            case let .injury(notice):
                levelUp = nil
                returnNotice = nil
                injury = InjuryNoticeFeature.State(notice: notice)
            case let .levelUp(levelUp):
                injury = nil
                returnNotice = nil
                self.levelUp = SkillChoiceFeature.State(
                    offerID: levelUp.offer.id,
                    player: levelUp.player,
                    choices: levelUp.choices
                )
            case let .returnNotice(notice):
                injury = nil
                levelUp = nil
                returnNotice = ReturnNoticeFeature.State(notice: notice)
            }
        }
    }

    enum Notice: Equatable, Sendable {
        case injury(InjuryNotice)
        case levelUp(LevelUp)
        case returnNotice(ReturnNotice)
    }

    /// One player earned a skill. The player is a snapshot the matchweek refreshes after each choice.
    struct LevelUp: Equatable, Sendable {
        var offer: SkillOffer
        var player: Player
        var choices: [SkillChoice]
    }

    enum FollowUp: Equatable, Sendable {
        case nextWeek
        case championship
    }

    enum Action {
        case injury(PresentationAction<InjuryNoticeFeature.Action>)
        case levelUp(PresentationAction<SkillChoiceFeature.Action>)
        case returnNotice(PresentationAction<ReturnNoticeFeature.Action>)
        /// The matchweek applied the skill. Show whatever comes next.
        case skillApplied
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case readInjury(id: String)
            case readReturn(id: String)
            case applySkill(offerID: String, stat: PlayerStat)
            case spendOffer(offerID: String)
            case finished(FollowUp?)
            case abandoned
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .injury(.presented(.delegate(.dismissed))),
                    .returnNotice(.presented(.delegate(.dismissed))):
                return advance(&state)

            case let .levelUp(.presented(.delegate(.chose(stat)))):
                guard case let .levelUp(levelUp) = state.notices[state.index] else { return .none }
                return .send(.delegate(.applySkill(offerID: levelUp.offer.id, stat: stat)))

            case .skillApplied:
                return advance(&state)

            case .injury(.dismiss), .levelUp(.dismiss), .returnNotice(.dismiss):
                return .send(.delegate(.abandoned))

            case .injury, .levelUp, .returnNotice, .delegate:
                return .none
            }
        }
        .ifLet(\.$injury, action: \.injury) {
            InjuryNoticeFeature()
        }
        .ifLet(\.$levelUp, action: \.levelUp) {
            SkillChoiceFeature()
        }
        .ifLet(\.$returnNotice, action: \.returnNotice) {
            ReturnNoticeFeature()
        }
    }

    private func advance(_ state: inout State) -> Effect<Action> {
        guard state.notices.indices.contains(state.index) else { return .none }
        let current = state.notices[state.index]
        return .concatenate(read(current), moveForward(&state))
    }

    private func read(_ notice: Notice) -> Effect<Action> {
        switch notice {
        case let .injury(notice):
            return .send(.delegate(.readInjury(id: notice.id)))
        case let .returnNotice(notice):
            return .send(.delegate(.readReturn(id: notice.id)))
        case .levelUp:
            return .none
        }
    }

    /// The next notice that still needs a sheet. A level-up the player can no longer take is spent instead.
    private func moveForward(_ state: inout State) -> Effect<Action> {
        var next = state.index + 1
        while state.notices.indices.contains(next) {
            if case let .levelUp(levelUp) = state.notices[next], levelUp.player.canGrow == false {
                state.index = next
                return .send(.delegate(.spendOffer(offerID: levelUp.offer.id)))
            }
            state.index = next
            state.presentCurrent()
            return .none
        }
        return .send(.delegate(.finished(state.followUp)))
    }
}
