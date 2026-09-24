import ComposableArchitecture
import SwiftUI

struct ClubSelectionView: View {
    @Bindable var store: StoreOf<ClubSelectionFeature>
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                header
                content
            }
            .padding(Theme.Space.lg)
            .readingWidth()
        }
        .themeScreen()
        .navigationTitle("Take a club")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.accent)
        .onAppear { store.send(.view(.onAppear)) }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: store.clubs.count)
        .sensoryFeedback(.selection, trigger: store.lastPickedID)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Matchday one")
                .font(.caption.weight(.semibold).smallCaps())
                .foregroundStyle(Theme.accent)
            Text("Take a club")
                .font(.largeTitle.weight(.black))
                .fontDesign(.rounded)
                .foregroundStyle(Theme.ink)
            Text("The shirt is real. The names are not.")
                .font(.title3)
                .fontDesign(.serif)
                .foregroundStyle(Theme.inkMuted)
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
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if store.clubs.isEmpty {
            VStack(spacing: Theme.Space.sm) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Drawing the squads.")
                    .font(.body)
                    .foregroundStyle(Theme.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .accessibilityElement(children: .combine)
        } else if sizeClass == .regular {
            HStack(alignment: .top, spacing: Theme.Space.md) {
                ForEach(store.clubs) { club in
                    clubCard(club)
                }
            }
        } else {
            VStack(spacing: Theme.Space.md) {
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
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(club.name)
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: Theme.Space.sm)
                    Text(role(of: club))
                        .font(.caption.weight(.semibold).smallCaps())
                        .foregroundStyle(Theme.accent)
                }
                Text(club.nickname)
                    .font(.body)
                    .fontDesign(.serif)
                    .foregroundStyle(Theme.inkMuted)
                Text("Overall \(club.overall)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text("Attack \(club.attack)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.ink)
                Text("Defense \(club.defense)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.ink)
            }
            .padding(Theme.Space.md)
            .frame(maxWidth: .infinity, minHeight: Theme.control, alignment: .leading)
            .background(Theme.surface)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(club.kit.primary.color)
                    .frame(width: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.shadow, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(club.name), \(club.nickname), overall \(club.overall), attack \(club.attack), defense \(club.defense), \(role(of: club))")
        .accessibilityHint("Takes the job and opens the squad")
    }

    private func role(of club: Club) -> String {
        guard let other = store.clubs.first(where: { $0.id != club.id }) else { return "" }
        if club.attack == other.attack { return "Level" }
        return club.attack > other.attack ? "Favorite" : "Underdog"
    }
}
