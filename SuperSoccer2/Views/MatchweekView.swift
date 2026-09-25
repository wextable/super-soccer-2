import ComposableArchitecture
import SwiftUI

struct MatchweekView: View {
    @Bindable var store: StoreOf<MatchweekFeature>
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Club", systemImage: "person.3", value: MatchweekFeature.State.Tab.club) {
                ClubTab(store: store)
            }
            Tab("Table", systemImage: "list.number", value: MatchweekFeature.State.Tab.table) {
                TableTab(store: store)
            }
            Tab("Week", systemImage: "calendar", value: MatchweekFeature.State.Tab.week) {
                WeekTab(store: store)
            }
            Tab("Match", systemImage: "sportscourt", value: MatchweekFeature.State.Tab.match) {
                MatchTab(store: store)
            }
        }
        .tabViewStyle(.tabBarOnly)
        .themeScreen()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.colors.action.color)
        .toolbarBackground(theme.colors.background.color, for: .tabBar)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.weekIndex)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: store.currentWeekIsInTheTable)
        .navigationDestination(
            item: $store.scope(state: \.leaders, action: \.leaders)
        ) { leadersStore in
            LeadersView(store: leadersStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.championship, action: \.championship)
        ) { championshipStore in
            ChampionshipView(store: championshipStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.team, action: \.team)
        ) { teamStore in
            TeamView(store: teamStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.player, action: \.player)
        ) { playerStore in
            PlayerDetailView(store: playerStore)
        }
        .fullScreenCover(
            item: $store.scope(state: \.highlight, action: \.highlight)
        ) { highlightStore in
            MatchLineView(week: store, highlight: highlightStore)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.committedWeeks)
    }

    private var tabSelection: Binding<MatchweekFeature.State.Tab> {
        Binding(
            get: { store.tab },
            set: { newValue in
                guard newValue != store.tab else { return }
                store.send(.view(.tabSelected(newValue)))
            }
        )
    }

    private var title: String {
        switch store.tab {
        case .club:
            store.userClub?.name ?? "Club"
        case .table:
            "Week \(store.weekNumber)"
        case .week:
            "Week \(store.weekNumber)"
        case .match:
            "Match"
        }
    }
}

/// The kickoff cover. The reel stays up through full time, then this swaps in the stats screen.
struct MatchLineView: View {
    @Bindable var week: StoreOf<MatchweekFeature>
    let highlight: StoreOf<HighlightFeature>

    var body: some View {
        if let statsStore = week.scope(state: \.stats, action: \.stats.presented) {
            MatchStatsView(store: statsStore)
        } else {
            HighlightView(store: highlight)
        }
    }
}
