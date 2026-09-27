import ComposableArchitecture
import Foundation

/// Rest or Play on the club roster. Nothing changes until a name in the dialog is chosen.
@Reducer
struct SubstitutionFeature {
    @ObservableState
    struct State: Equatable {
        var kind: Kind
        var subject: Player
        var suggestion: Player
        var others: [Player]

        enum Kind: Equatable, Sendable {
            case rest
            case play
        }

        /// Rest keeps the bring-in suggestion. Play asks who leaves, with the same shape.
        var heading: String {
            switch kind {
            case .rest: "Bring in"
            case .play: "Replace"
            }
        }

        var primaryTitle: String {
            switch kind {
            case .rest: "Rest, bring in \(suggestion.fullName)"
            case .play: "Play, replace \(suggestion.fullName)"
            }
        }

        var othersHeading: String { "Or someone else" }

        var suggestionDetail: String {
            "\(suggestion.overall) · \(suggestion.fitnessBand().label) \(suggestion.condition)"
        }

        /// Sit this starter. The suggestion is the best teammate who can come in.
        static func resting(_ starter: Player, in players: [Player]) -> State? {
            guard starter.isStarter, starter.injury == nil,
                  let suggestion = WeekBetween.bestFit(replacing: starter, in: players)
            else { return nil }
            return State(
                kind: .rest,
                subject: starter,
                suggestion: suggestion,
                others: WeekBetween.alternatives(replacing: starter, in: players)
            )
        }

        /// Bring this bench player on. The suggestion is the starter they would sit.
        static func playing(_ bench: Player, in players: [Player]) -> State? {
            guard !bench.isStarter, bench.injury == nil,
                  let suggestion = WeekBetween.starterToSit(for: bench, in: players)
            else { return nil }
            return State(
                kind: .play,
                subject: bench,
                suggestion: suggestion,
                others: WeekBetween.otherStarters(for: bench, in: players)
            )
        }

        static func make(_ kind: Kind, player: Player, in players: [Player]) -> State? {
            switch kind {
            case .rest: resting(player, in: players)
            case .play: playing(player, in: players)
            }
        }

        /// The chosen row. Rest’s choice comes in. Play’s choice is the starter who sits.
        func swap(chosenID: Player.ID) -> (outgoing: Player.ID, incoming: Player.ID)? {
            let known = chosenID == suggestion.id || others.contains { $0.id == chosenID }
            guard known else { return nil }
            switch kind {
            case .rest:
                return (subject.id, chosenID)
            case .play:
                return (chosenID, subject.id)
            }
        }
    }

    enum Action {
        case view(View)
        case delegate(Delegate)

        @CasePathable
        enum View {
            case suggestionTapped
            case otherTapped(Player.ID)
            case cancelTapped
        }

        @CasePathable
        enum Delegate {
            case chosen(Player.ID)
            case cancelled
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.suggestionTapped):
                return .send(.delegate(.chosen(state.suggestion.id)))

            case let .view(.otherTapped(id)):
                guard state.others.contains(where: { $0.id == id }) else { return .none }
                return .send(.delegate(.chosen(id)))

            case .view(.cancelTapped):
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
