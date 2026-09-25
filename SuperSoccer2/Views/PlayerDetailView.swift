import ComposableArchitecture
import SwiftUI

struct PlayerDetailView: View {
    let store: StoreOf<PlayerDetailFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                ratings
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle(store.player.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text(positionName)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text(store.player.fullName)
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text(store.clubName)
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
            Text("Overall \(store.player.overall)")
                .font(theme.type.overall)
                .foregroundStyle(theme.colors.text.color)
        }
        .accessibilityElement(children: .combine)
    }

    private var ratings: some View {
        WeekCard {
            ratingRow("Speed", store.player.ratings.speed, isLast: false)
            ratingRow("Shooting", store.player.ratings.shooting, isLast: false)
            ratingRow("Passing", store.player.ratings.passing, isLast: false)
            ratingRow("Dribbling", store.player.ratings.dribbling, isLast: false)
            ratingRow("Defending", store.player.ratings.defending, isLast: false)
            ratingRow("Goalkeeping", store.player.ratings.goalkeeping, isLast: true)
        }
    }

    private func ratingRow(_ name: String, _ value: Int, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(theme.type.playerName)
                    .foregroundStyle(theme.colors.text.color)
                Spacer()
                Text("\(value)")
                    .font(theme.type.playerOverall)
                    .foregroundStyle(theme.colors.text.color)
            }
            .frame(minHeight: theme.metrics.minimumControl)
            if !isLast {
                WeekHairline()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) \(value)")
    }

    private var positionName: String {
        switch store.player.position {
        case .keeper: "Keeper"
        case .defender: "Defender"
        case .midfielder: "Midfielder"
        case .forward: "Forward"
        }
    }
}
