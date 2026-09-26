import ComposableArchitecture
import SwiftUI

struct ClubSelectionView: View {
    @Bindable var store: StoreOf<ClubSelectionFeature>
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.space.lg) {
                header
                content
            }
            .padding(theme.space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Take a club")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.colors.action.color)
        .onAppear { store.send(.view(.onAppear)) }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: store.clubs.count)
        .sensoryFeedback(.selection, trigger: store.lastPickedID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.space.xs) {
            Text("The season")
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.action.color)
            Text("Take a club")
                .font(theme.type.display)
                .foregroundStyle(theme.colors.text.color)
            Text("The shirt is real. The names are not.")
                .font(theme.type.tagline)
                .foregroundStyle(theme.colors.secondaryText.color)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if store.didFailToLoad {
            ContentUnavailableView(
                "The squads did not come out",
                systemImage: "exclamationmark.triangle",
                description: Text("Leave and open the app again.")
            )
            .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
        } else if store.clubs.isEmpty {
            VStack(spacing: theme.space.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(theme.colors.action.color)
                Text("Drawing the squads.")
                    .font(theme.type.body)
                    .foregroundStyle(theme.colors.secondaryText.color)
            }
            .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyMinHeight)
            .accessibilityElement(children: .combine)
        } else if sizeClass == .regular {
            HStack(alignment: .top, spacing: theme.space.md) {
                ForEach(store.clubs) { club in
                    clubCard(club)
                }
            }
        } else {
            VStack(spacing: theme.space.md) {
                ForEach(store.clubs) { club in
                    clubCard(club)
                }
            }
        }
    }

    private func clubCard(_ club: Club) -> some View {
        Button {
            store.send(.view(.clubTapped(club.id)))
        } label: {
            VStack(alignment: .leading, spacing: theme.space.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(club.name)
                        .font(theme.type.clubName)
                        .foregroundStyle(theme.colors.text.color)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: theme.space.sm)
                    Text(role(of: club))
                        .font(theme.type.eyebrow)
                        .foregroundStyle(theme.colors.action.color)
                }
                Text(club.nickname)
                    .font(theme.type.tagline)
                    .foregroundStyle(theme.colors.secondaryText.color)
                Text("Overall \(club.overall)")
                    .font(theme.type.overall)
                    .foregroundStyle(theme.colors.text.color)
                Text("Attack \(club.attack)")
                    .font(theme.type.rating)
                    .foregroundStyle(theme.colors.text.color)
                Text("Defense \(club.defense)")
                    .font(theme.type.rating)
                    .foregroundStyle(theme.colors.text.color)
            }
            .padding(theme.space.md)
            .frame(maxWidth: .infinity, minHeight: theme.metrics.minimumControl, alignment: .leading)
            .background(theme.colors.card.color)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(club.kit.primary.color)
                    .frame(width: theme.metrics.accentBar)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.color, radius: theme.metrics.shadowRadius, y: theme.metrics.shadowY)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(club.name), \(club.nickname), overall \(club.overall), attack \(club.attack), defense \(club.defense), \(role(of: club))")
        .accessibilityHint("Takes the job and opens the week")
    }

    private func role(of club: Club) -> String {
        guard let other = store.clubs.first(where: { $0.id != club.id }) else { return "" }
        if club.attack == other.attack { return "Level" }
        return club.attack > other.attack ? "Favorite" : "Underdog"
    }
}
