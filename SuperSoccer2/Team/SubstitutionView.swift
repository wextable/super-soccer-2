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
                        .foregroundStyle(theme.colors.text.color)
                    suggestion
                    if !store.others.isEmpty {
                        others
                    }
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

    private var suggestion: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(store.heading)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            Button {
                store.send(.view(.suggestionTapped))
            } label: {
                VStack(spacing: theme.space.xxs) {
                    Text(store.primaryTitle)
                    Text(store.suggestionDetail)
                        .font(theme.type.captionNumber)
                }
            }
            .buttonStyle(ThemeActionButtonStyle())
            .accessibilityLabel(suggestionLabel)
        }
    }

    private var others: some View {
        VStack(alignment: .leading, spacing: theme.space.sm) {
            Text(store.othersHeading)
                .font(theme.type.eyebrow)
                .foregroundStyle(theme.colors.secondaryText.color)
            WeekCard {
                ForEach(Array(store.others.enumerated()), id: \.element.id) { index, player in
                    Button {
                        store.send(.view(.otherTapped(player.id)))
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
                    .accessibilityLabel(otherLabel(player))
                    if index < store.others.count - 1 {
                        WeekHairline()
                    }
                }
            }
        }
    }

    private var suggestionLabel: String {
        let detail = "overall \(store.suggestion.overall), \(store.suggestion.fitnessBand().label), fitness \(store.suggestion.condition)"
        switch store.kind {
        case .rest:
            return "Rest \(store.subject.fullName) and bring in \(store.suggestion.fullName), \(detail)"
        case .play:
            return "Play \(store.subject.fullName) and replace \(store.suggestion.fullName), \(detail)"
        }
    }

    private func otherLabel(_ player: Player) -> String {
        let verb = store.kind == .rest ? "Bring in" : "Replace"
        return "\(verb) \(player.fullName), overall \(player.overall), \(player.fitnessBand().label), fitness \(player.condition)"
    }
}
