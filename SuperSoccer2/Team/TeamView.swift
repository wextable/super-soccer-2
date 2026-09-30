import ComposableArchitecture
import SwiftUI

struct TeamView: View {
    @Bindable var store: StoreOf<TeamFeature>

    var body: some View {
        TeamScreen(
            club: store.club,
            won: store.won,
            lost: store.lost,
            drawn: store.drawn,
            place: store.place,
            canManage: store.canManage,
            onPlayer: { store.send(.view(.playerTapped($0))) },
            onRest: store.canManage ? { store.send(.view(.restStarter($0))) } : nil,
            onPlay: store.canManage ? { store.send(.view(.playBench($0))) } : nil
        )
        .navigationTitle(store.club.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $store.scope(state: \.player, action: \.player)
        ) { playerStore in
            PlayerDetailView(store: playerStore)
        }
        .sheet(item: $store.scope(state: \.substitution, action: \.substitution)) { substitutionStore in
            SubstitutionView(store: substitutionStore)
        }
    }
}

/// Squad and ratings. The Club tab and the table drill-in share this layout.
struct TeamScreen: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var club: Club
    var won: Int
    var lost: Int
    var drawn: Int
    var place: Int?
    var canManage: Bool = false
    var onPlayer: (Player.ID) -> Void
    var onRest: ((Player.ID) -> Void)? = nil
    var onPlay: ((Player.ID) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                if !club.injuryLines.isEmpty {
                    injuries
                }
                roster(title: "Starting", players: club.starters)
                roster(title: "Bench", players: club.bench)
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: club.starters.map(\.id))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            HStack(spacing: theme.space.sm) {
                ClubCrest(clubID: club.id, scale: .mark)
                Text(club.name)
                    .font(theme.type.display)
                    .foregroundStyle(theme.colors.title.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
                if let place {
                    Text("\(LeagueTable.placeWord(place)) in table")
                        .font(theme.type.homeLine)
                        .foregroundStyle(theme.colors.secondaryText.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("\(won)/\(lost)/\(drawn)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityLabel("\(won) wins, \(lost) losses, \(drawn) draws")
            }
            Text("Overall \(club.overall)  ·  Attack \(club.attack)  ·  Defense \(club.defense)")
                .font(theme.type.overall)
                .foregroundStyle(theme.colors.text.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .accessibilityElement(children: .combine)
        .pixelHeader()
    }

    private var injuries: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            SectionLabel(text: "Injuries")
            WeekCard {
                ForEach(Array(club.injuryLines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .firstTextBaseline, spacing: theme.space.sm) {
                        Circle()
                            .fill(theme.colors.fitnessRed.color)
                            .frame(width: theme.space.xs, height: theme.space.xs)
                        Text(line)
                            .font(theme.type.body)
                            .foregroundStyle(theme.colors.text.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: theme.metrics.minimumControl)
                    .accessibilityElement(children: .combine)
                    if index < club.injuryLines.count - 1 {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func roster(title: String, players: [Player]) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            SectionLabel(text: title)
            if players.isEmpty {
                Text(title == "Bench" ? "The bench is empty." : "No one is starting.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
            } else {
                WeekCard {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        playerRow(player)
                        if index < players.count - 1 {
                            WeekHairline()
                        }
                    }
                }
            }
        }
    }

    private func playerRow(_ player: Player) -> some View {
        let band = player.fitnessBand()
        let mark = player.injury == nil ? "\(band.label) · \(player.condition)" : "Out"
        let showRest = onRest != nil
            && player.isStarter
            && player.injury == nil
            && WeekBetween.bestFit(replacing: player, in: club.players) != nil
        let showPlay = onPlay != nil
            && !player.isStarter
            && player.injury == nil
            && WeekBetween.starterToSit(for: player, in: club.players) != nil
        return HStack(spacing: theme.space.sm) {
            Button {
                onPlayer(player.id)
            } label: {
                HStack(spacing: theme.space.sm) {
                    RoundedRectangle(cornerRadius: theme.metrics.pixelChrome ? 0 : theme.space.sm / 2, style: .continuous)
                        .fill(bandColor(player))
                        .frame(width: theme.space.sm, height: theme.space.sm)
                        .accessibilityHidden(true)
                    PositionMark(position: player.position)
                    VStack(alignment: .leading, spacing: theme.space.xxs) {
                        Text(player.fullName)
                            .font(theme.type.playerName)
                            .foregroundStyle(theme.colors.text.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(mark)
                            .font(theme.type.captionNumber)
                            .foregroundStyle(bandColor(player))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    StarterRating(player: player)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playerLabel(player, mark: mark))
            if showRest {
                Button("Rest") {
                    onRest?(player.id)
                }
                .font(theme.type.button)
                .foregroundStyle(theme.colors.action.color)
                .frame(minHeight: theme.metrics.minimumControl)
                .accessibilityLabel("Rest \(player.fullName)")
            }
            if showPlay {
                Button("Play") {
                    onPlay?(player.id)
                }
                .font(theme.type.button)
                .foregroundStyle(theme.colors.action.color)
                .frame(minHeight: theme.metrics.minimumControl)
                .accessibilityLabel("Play \(player.fullName)")
            }
        }
        .frame(minHeight: theme.metrics.minimumControl)
    }

    private func playerLabel(_ player: Player, mark: String) -> String {
        var label = "\(player.fullName), \(player.position.label), \(mark), overall \(player.overall)"
        if player.isStarter, player.injury == nil, player.overall != player.optimalOverall {
            label += ", full fitness \(player.optimalOverall)"
        }
        return label
    }

    private func bandColor(_ player: Player) -> Color {
        if player.injury != nil { return theme.colors.fitnessRed.color }
        return theme.colors.fitness(player.fitnessBand())
    }
}
