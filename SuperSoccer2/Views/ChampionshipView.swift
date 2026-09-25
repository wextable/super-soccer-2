import ComposableArchitecture
import SwiftUI

struct ChampionshipView: View {
    @Bindable var store: StoreOf<ChampionshipFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                celebration
                board("Goals", rows: store.goals)
                board("Assists", rows: store.assists)
                board("Saves", rows: store.saves)
                awards
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Championship")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $store.scope(state: \.player, action: \.player)
        ) { playerStore in
            PlayerDetailView(store: playerStore)
        }
    }

    private var celebration: some View {
        VStack(spacing: theme.space.md) {
            Image(systemName: "trophy.fill")
                .font(theme.type.display)
                .foregroundStyle(theme.colors.score.color)
                .frame(minWidth: theme.metrics.minimumControl, minHeight: theme.metrics.minimumControl)
                .accessibilityHidden(true)
            Text("Champions")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.score.color)
            Text(store.championName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
                .multilineTextAlignment(.center)
            Text(store.nickname)
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
                .multilineTextAlignment(.center)
            Text("Top of the table.")
                .font(theme.type.body)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.space.lg)
        .background {
            RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous)
                .fill(theme.colors.card.color)
            RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous)
                .strokeBorder(store.kit.primary.color, lineWidth: theme.metrics.accentBar)
        }
        .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Champions, \(store.championName), \(store.nickname)")
    }

    private var awards: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text("Awards")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(store.record.awards) { award in
                    Button {
                        store.send(.view(.awardTapped(award.kind)))
                    } label: {
                        HStack(spacing: theme.space.sm) {
                            VStack(alignment: .leading, spacing: theme.space.xxs) {
                                Text(award.kind.title)
                                    .font(theme.type.eyebrow)
                                    .foregroundStyle(theme.colors.action.color)
                                Text(award.player.fullName)
                                    .font(theme.type.playerName)
                                    .foregroundStyle(theme.colors.text.color)
                                Text(award.clubName)
                                    .font(theme.type.captionNumber)
                                    .foregroundStyle(theme.colors.secondaryText.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(statLine(award))
                                .font(theme.type.captionNumber)
                                .foregroundStyle(theme.colors.text.color)
                                .multilineTextAlignment(.trailing)
                        }
                        .frame(minHeight: theme.metrics.minimumControl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(award.kind.title), \(award.player.fullName), \(award.clubName), \(statLine(award))")
                    if award.id != store.record.awards.last?.id {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func board(_ title: String, rows: [LeagueLeaders.Row]) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(title)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            if rows.isEmpty {
                Text("None yet")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: theme.metrics.minimumControl)
            } else {
                WeekCard {
                    ForEach(rows) { row in
                        Button {
                            store.send(.view(.leaderTapped(row.player.id)))
                        } label: {
                            HStack(spacing: theme.space.sm) {
                                Text(row.player.fullName)
                                    .font(theme.type.playerName)
                                    .foregroundStyle(theme.colors.text.color)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(row.count)")
                                    .font(theme.type.playerOverall)
                                    .foregroundStyle(theme.colors.text.color)
                            }
                            .frame(minHeight: theme.metrics.minimumControl)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(row.player.fullName), \(row.clubName), \(row.count) \(title.lowercased())")
                        if row.id != rows.last?.id {
                            WeekHairline()
                        }
                    }
                }
            }
        }
    }

    private func statLine(_ award: Award) -> String {
        switch award.kind {
        case .bestKeeper:
            "\(award.stats.saves) saves"
        case .goldenBoot:
            "\(award.stats.goals) goals"
        case .mvp, .bestDefender, .bestMidfielder, .bestForward:
            "\(award.stats.goals) goals, \(award.stats.assists) assists"
        }
    }
}
