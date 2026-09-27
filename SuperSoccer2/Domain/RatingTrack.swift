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

    /// The rating today, then only the points this skill can still add. Nothing past 99 is drawn.
    static func growth(_ projection: SkillProjection) -> RatingTrack {
        RatingTrack(
            filledPoints: projection.current,
            markedPoints: projection.next - projection.current,
            emptyPoints: trackPoints - projection.next
        )
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
