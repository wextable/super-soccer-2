import ComposableArchitecture
import SwiftUI

/// The roster’s rest and play choice. A name has to be tapped. Nothing is picked in advance.
struct SubstitutionView: View {
    let store: StoreOf<SubstitutionFeature>
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.space.lg) {
                    Text(store.subject.fullName)
                        .font(theme.type.clubName)
                        .foregroundStyle(theme.colors.title.color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .pixelHeader()
                    candidates
                }
                .padding(theme.space.lg)
                .readingWidth()
            }
            .themeScreen()
            .navigationTitle(store.kind == .rest ? "Rest" : "Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.colors.background.color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.view(.cancelTapped))
                    }
                }
            }
        }
        .tint(theme.colors.action.color)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.colors.background.color)
    }

    private var candidates: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(store.heading)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(Array(store.candidates.enumerated()), id: \.element.id) { index, player in
                    Button {
                        store.send(.view(.nameTapped(player.id)))
                    } label: {
                        HStack(spacing: theme.space.sm) {
                            Circle()
                                .fill(theme.colors.fitness(player.fitnessBand()))
                                .frame(width: theme.space.sm, height: theme.space.sm)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: theme.space.xxs) {
                                Text(player.fullName)
                                    .font(theme.type.playerName)
                                    .foregroundStyle(theme.colors.text.color)
                                Text("\(player.fitnessBand().label) · \(player.condition)")
                                    .font(theme.type.captionNumber)
                                    .foregroundStyle(theme.colors.fitness(player.fitnessBand()))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(player.overall)")
                                .font(theme.type.playerOverall)
                                .foregroundStyle(theme.colors.text.color)
                        }
                        .frame(minHeight: theme.metrics.minimumControl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(nameLabel(player))
                    if index < store.candidates.count - 1 {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private func nameLabel(_ player: Player) -> String {
        "\(store.heading) \(player.fullName), overall \(player.overall), \(player.fitnessBand().label), fitness \(player.condition)"
    }
}
