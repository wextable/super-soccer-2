import ComposableArchitecture
import Foundation

/// Rest or Play on the club roster. Nothing changes until a name in the dialog is chosen.
@Reducer
struct SubstitutionFeature {
    @ObservableState
    struct State: Equatable {
        var kind: Kind
        var subject: Player
        /// Rest leads with the best teammate who can come in. Play lists starters lowest overall first.
        var candidates: [Player]

        enum Kind: Equatable, Sendable {
            case rest
            case play
        }

        /// Rest asks who comes in. Play asks who leaves, lowest overall first.
        var heading: String {
            switch kind {
            case .rest: "Replace with"
            case .play: "Replace"
            }
        }

        /// Sit this starter. The first name is the best teammate who can come in.
        static func resting(_ starter: Player, in players: [Player]) -> State? {
            guard starter.isStarter, starter.injury == nil,
                  let suggestion = WeekBetween.bestFit(replacing: starter, in: players)
            else { return nil }
            return State(
                kind: .rest,
                subject: starter,
                candidates: [suggestion] + WeekBetween.alternatives(replacing: starter, in: players)
            )
        }

        /// Bring this bench player on. Names are the starters they can replace, lowest overall first.
        static func playing(_ bench: Player, in players: [Player]) -> State? {
            guard !bench.isStarter, bench.injury == nil,
                  let suggestion = WeekBetween.starterToSit(for: bench, in: players)
            else { return nil }
            return State(
                kind: .play,
                subject: bench,
                candidates: [suggestion] + WeekBetween.otherStarters(for: bench, in: players)
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
            guard candidates.contains(where: { $0.id == chosenID }) else { return nil }
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
            case nameTapped(Player.ID)
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
            case let .view(.nameTapped(id)):
                guard state.candidates.contains(where: { $0.id == id }) else { return .none }
                return .send(.delegate(.chosen(id)))

            case .view(.cancelTapped):
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
