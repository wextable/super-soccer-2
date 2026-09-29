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
            HStack(spacing: theme.space.sm) {
                ClubCrest(clubID: store.record.championClubID, scale: .mark)
                Text(store.championName)
                    .font(theme.type.display)
                    .foregroundStyle(theme.colors.title.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            Text(store.nickname)
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
                .multilineTextAlignment(.center)
            if theme.metrics.pixelChrome {
                PixelRule()
                    .frame(width: 120)
            }
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
            SectionLabel(text: "Awards")
            WeekCard {
                ForEach(store.record.awards) { award in
                    Button {
                        store.send(.view(.awardTapped(award.kind)))
                    } label: {
                        HStack(spacing: theme.space.sm) {
                            VStack(alignment: .leading, spacing: theme.space.sm) {
                                Text(award.kind.title)
                                    .font(theme.type.eyebrow)
                                    .foregroundStyle(awardInk(award.kind))
                                Text(award.player.fullName)
                                    .font(theme.type.playerName)
                                    .foregroundStyle(isYours(award) ? theme.colors.action.color : theme.colors.text.color)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                HStack(spacing: theme.space.xs) {
                                    ClubCrest(clubID: award.clubID)
                                    Text(isYours(award) ? "Your club · \(award.clubName)" : award.clubName)
                                        .font(theme.type.captionNumber)
                                        .foregroundStyle(isYours(award) ? theme.colors.action.color : theme.colors.secondaryText.color)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(statLine(award))
                                .font(theme.type.captionNumber)
                                .foregroundStyle(theme.colors.text.color)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, theme.space.sm)
                        .frame(minHeight: theme.metrics.minimumControl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(awardLabel(award))
                    if award.id != store.record.awards.last?.id {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func board(_ title: String, rows: [LeagueLeaders.Row]) -> some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            SectionLabel(text: title)
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
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
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

    private func awardInk(_ kind: AwardKind) -> Color {
        switch kind {
        case .bestKeeper: theme.colors.color(for: .keeper)
        case .bestDefender: theme.colors.color(for: .defender)
        case .bestMidfielder: theme.colors.color(for: .midfielder)
        case .bestForward: theme.colors.color(for: .forward)
        case .mvp, .goldenBoot: theme.colors.action.color
        }
    }

    private func awardLabel(_ award: Award) -> String {
        let club = isYours(award) ? "your club, \(award.clubName)" : award.clubName
        return "\(award.kind.title), \(award.player.fullName), \(club), \(statLine(award))"
    }

    private func isYours(_ award: Award) -> Bool {
        award.clubID == store.userClubID
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
