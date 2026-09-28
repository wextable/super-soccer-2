import Foundation

/// How far a rating fills a horizontal bar.
/// The scale is ten units, one unit per ten points, so 100 is the width. A rating stops at 99.
/// The drawn track ends at that attribute’s ceiling. The fill ends at the current rating.
/// Two ratings of 80 fill the same length. The higher ceiling is the longer track.
struct RatingTrack: Equatable, Sendable {
    static let pointsPerUnit = 10
    static let trackPoints = 100

    var filledPoints: Int
    var markedPoints: Int
    /// Track still open after the fill and the mark, up to the ceiling.
    var emptyPoints: Int
    /// Right edge of the track, on the same 1–99 scale as `trackPoints`.
    var ceiling: Int

    /// Full-fitness rating, then the points condition has taken off, inside a track that ends at potential.
    static func fitness(full: Int, current: Int, potential: Int) -> RatingTrack {
        let full = min(99, max(0, full))
        let current = min(full, max(0, current))
        let ceiling = min(99, max(potential, full))
        return RatingTrack(
            filledPoints: current,
            markedPoints: full - current,
            emptyPoints: ceiling - full,
            ceiling: ceiling
        )
    }

    /// How much of the bar the current level has filled. The empty stretch is what is left before the next level.
    static func experience(current: Int, required: Int) -> RatingTrack {
        let required = max(required, 1)
        let current = min(max(0, current), required)
        let filled = min(trackPoints, Int((Double(current) / Double(required) * Double(trackPoints)).rounded()))
        return RatingTrack(
            filledPoints: filled,
            markedPoints: 0,
            emptyPoints: trackPoints - filled,
            ceiling: trackPoints
        )
    }

    /// The rating today, then only the points this skill can still add. The preview stays inside the ceiling.
    static func growth(_ projection: SkillProjection) -> RatingTrack {
        let ceiling = max(projection.ceiling, projection.next)
        return RatingTrack(
            filledPoints: projection.current,
            markedPoints: projection.next - projection.current,
            emptyPoints: ceiling - projection.next,
            ceiling: ceiling
        )
    }
}

/// Experience already banked toward the next level, and how much that level still costs.
struct ExperienceProgress: Equatable, Sendable {
    var level: Int
    var current: Int
    var required: Int

    var remaining: Int { max(0, required - current) }

    var track: RatingTrack {
        RatingTrack.experience(current: current, required: required)
    }

    /// `40/110`. The bar and this reading are the same distance.
    var reading: String { "\(current)/\(required)" }

    static func make(player: Player, tuning: WeekTuning = .current) -> ExperienceProgress {
        let required = max(tuning.requiredXP(level: player.level), 1)
        let current = min(max(0, player.xp), required)
        return ExperienceProgress(level: player.level, current: current, required: required)
    }
}

/// Where a skill would land. The boost is the one `WeekTuning` already gives that stat, cut off at the ceiling.
struct SkillProjection: Equatable, Sendable {
    var current: Int
    var next: Int
    var ceiling: Int
    /// False when the stat is already at its ceiling. That choice cannot be spent.
    var available: Bool

    /// `80→85` while there is room. A stat at its ceiling is just the number.
    var reading: String {
        guard available, next != current else { return "\(current)" }
        return "\(current)→\(next)"
    }

    static func make(current: Int, boost: Int, ceiling: Int = 99) -> SkillProjection {
        let ceiling = min(99, max(1, ceiling))
        let current = max(0, current)
        let room = max(0, ceiling - current)
        let gain = min(room, max(0, boost))
        return SkillProjection(
            current: current,
            next: current + gain,
            ceiling: max(ceiling, current),
            available: current < ceiling
        )
    }
}
