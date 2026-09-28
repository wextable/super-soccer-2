import Foundation

/// How far a rating fills a horizontal bar. The track is ten units. One unit is ten points, so 100 fills it.
/// A rating stops at 99, which leaves the last point of the tenth unit empty.
struct RatingTrack: Equatable, Sendable {
    static let pointsPerUnit = 10
    static let trackPoints = 100

    var filledPoints: Int
    var markedPoints: Int
    var emptyPoints: Int

    /// Full-fitness rating, then the points condition has taken off, drawn back from that rating’s right edge.
    static func fitness(full: Int, current: Int) -> RatingTrack {
        let full = min(trackPoints, max(0, full))
        let current = min(full, max(0, current))
        return RatingTrack(
            filledPoints: current,
            markedPoints: full - current,
            emptyPoints: trackPoints - full
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
            emptyPoints: trackPoints - filled
        )
    }

    /// The rating today, then only the points this skill can still add. Nothing past 99 is drawn.
    static func growth(_ projection: SkillProjection) -> RatingTrack {
        RatingTrack(
            filledPoints: projection.current,
            markedPoints: projection.next - projection.current,
            emptyPoints: trackPoints - projection.next
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

/// Where a skill would land. The boost is the one `WeekTuning` already gives that stat.
struct SkillProjection: Equatable, Sendable {
    var current: Int
    var next: Int
    /// False when the stat is already 99. That choice cannot be spent.
    var available: Bool

    /// `80→85` while there is room. A stat at 99 is just `99`.
    var reading: String {
        guard available, next != current else { return "\(current)" }
        return "\(current)→\(next)"
    }

    static func make(current: Int, boost: Int) -> SkillProjection {
        let current = min(99, max(0, current))
        let gain = min(max(0, 99 - current), max(0, boost))
        return SkillProjection(current: current, next: current + gain, available: current < 99)
    }
}
