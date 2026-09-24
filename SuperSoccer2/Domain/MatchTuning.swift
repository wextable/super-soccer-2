import Foundation

/// The previous match’s goal-mean constants. The shape of the formula stays put.
/// `shipped` is GameConfig.GameAI as it left the old app. `current` is what this app rolls.
struct MatchTuning: Equatable, Sendable {
    /// Attack minus defense, divided by this, is one goal of mean.
    var ratingDiffPerGoal: Double
    /// Added only to the home mean.
    var homeFieldAdvantage: Double
    /// Bell-curve support, in goals, either side of zero. Standard deviation stays 1.
    var goalNoiseHalfWidth: Double
    /// Flat goals on both means, before home advantage.
    var baseGoals: Double

    static let shipped = MatchTuning(
        ratingDiffPerGoal: 7.5,
        homeFieldAdvantage: 0.25,
        goalNoiseHalfWidth: 3,
        baseGoals: 1
    )

    static let current = shipped

    func mean(attack: Int, defense: Int, home: Bool) -> Double {
        let gap = Double(attack - defense) / ratingDiffPerGoal + baseGoals
        return home ? gap + homeFieldAdvantage : gap
    }
}
