import Foundation

/// Full-pitch point. x is 0 on the left touchline and 1 on the right.
/// y is 0 on the north goal line and 1 on the south goal line.
struct PitchPoint: Equatable, Sendable {
    var x: Double
    var y: Double

    func distance(to other: PitchPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// The attacking third on a pitch whose ends stay put for the whole match.
    /// North (pitch y = 0) is the bottom of the screen. South (pitch y = 1) is the top.
    /// First half, home defends south, so that goal is at the top and home shoots down at the other.
    /// After the break the clubs swap ends, so home defends the bottom. Left stays left.
    func inAttackingView(of end: PitchEnd) -> PitchPoint {
        let depth = PitchGeometry.playDepth
        switch end {
        case .north:
            return PitchPoint(x: x, y: 1 - y / depth)
        case .south:
            return PitchPoint(x: x, y: (1 - y) / depth)
        }
    }

    func isInNet(of end: PitchEnd) -> Bool {
        abs(y - end.goalLine) < 0.000_000_1 && abs(x - 0.5) < PitchGeometry.goalHalfWidth - 0.006
    }

    func isInSixYard(of end: PitchEnd) -> Bool {
        let along = end == .north ? y : (1 - y)
        let depth = PitchGeometry.sixLength / PitchGeometry.length
        return along <= depth + 0.000_000_1 && abs(x - 0.5) <= PitchGeometry.sixHalfWidth + 0.000_000_1
    }
}

/// Which goal a club is attacking. The ends are real places on the pitch, not a camera flag.
enum PitchEnd: Equatable, Sendable {
    case north
    case south

    var goalLine: Double { self == .north ? 0 : 1 }

    /// First half: home attacks north, away attacks south. After the break they swap ends.
    static func attacked(byHome: Bool, minute: Int) -> PitchEnd {
        let firstHalf = minute <= HighlightScript.halfMinute
        if byHome {
            return firstHalf ? .north : .south
        }
        return firstHalf ? .south : .north
    }
}

enum PitchGeometry {
    static let length = 105.0
    static let width = 68.0
    /// Share of the pitch, measured from the goal, that a highlight plays in.
    static let playDepth = 0.40
    static let goalWidth = 7.32
    static let sixLength = 5.5
    static let sixWidth = 18.32
    static let boxLength = 16.5
    static let boxWidth = 40.32
    static let spot = 11.0
    static let arcRadius = 9.15
    static let cornerRadius = 1.0

    static var goalHalfWidth: Double { (goalWidth / width) / 2 }
    /// The drawn goal is three times the real posts, so a shot reads on the pitch.
    static var displayGoalHalfWidth: Double { goalHalfWidth * 3 }
    static var sixHalfWidth: Double { (sixWidth / width) / 2 }
    static var boxHalfWidth: Double { (boxWidth / width) / 2 }
    static var sixDepthLocal: Double { (sixLength / length) / playDepth }
    static var boxDepthLocal: Double { (boxLength / length) / playDepth }
    static var spotLocal: Double { (spot / length) / playDepth }
    static var arcRadiusLocalY: Double { (arcRadius / length) / playDepth }
    static var arcRadiusX: Double { arcRadius / width }
    static var cornerRadiusX: Double { cornerRadius / width }
    static var cornerRadiusLocalY: Double { (cornerRadius / length) / playDepth }
}

enum HighlightTemplate: String, Equatable, Sendable, CaseIterable {
    case wing
    case throughTheMiddle
    case counter
    case oneTwo
    case cutback
    case penalty
}

enum ShotFinish: Equatable, Sendable {
    case net
    case keeper
    case wide
    case over
}

struct HighlightActor: Equatable, Sendable, Identifiable {
    enum Role: String, Equatable, Sendable {
        case shooter
        case passer
        case teammate
        case defender
        case keeper
    }

    var id: Int
    var role: Role
    /// Attacking outfield players wear the club that has the chance. Keeper and defenders wear the other.
    var attacks: Bool
    var name: String
}

struct HighlightMove: Equatable, Sendable {
    var actorID: Int
    var start: PitchPoint
    var end: PitchPoint
}

struct HighlightBeat: Equatable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case carry
        case pass
        case shot
    }

    var kind: Kind
    /// Relative length. The reel plays the beats across one window.
    var weight: Double
    /// The player the ball leaves. A carry stays with them. A pass or shot is played by them.
    var ballOwner: Int
    var ballStart: PitchPoint
    var ballEnd: PitchPoint
    var moves: [HighlightMove]
}

struct HighlightPose: Equatable, Sendable {
    var ball: PitchPoint
    /// 0 until the shot, then how far that shot has traveled.
    var shotProgress: Double
    var places: [HighlightPlace]
}

struct HighlightPlace: Equatable, Sendable, Identifiable {
    var id: Int
    var point: PitchPoint
    var role: HighlightActor.Role
    var attacks: Bool
}

/// A seeded run of beats for one shot. The same shot and match seed always build the same script.
/// The minute chooses the half, and the half chooses which goal is attacked. It does not reshuffle the move.
struct HighlightScript: Equatable, Sendable {
    static let halfMinute = 45

    var template: HighlightTemplate
    var attackingEnd: PitchEnd
    var finish: ShotFinish
    var actors: [HighlightActor]
    var beats: [HighlightBeat]

    var ballStart: PitchPoint { beats[0].ballStart }
    var ballEnd: PitchPoint { beats[beats.count - 1].ballEnd }

    var ballEndsInNet: Bool {
        finish == .net && ballEnd.isInNet(of: attackingEnd)
    }

    static func make(shot: Shot, matchSeed: UInt64) -> HighlightScript {
        var builder = ScriptBuilder(shot: shot, matchSeed: matchSeed)
        return builder.build()
    }

    func pose(at progress: Double) -> HighlightPose {
        let placed = placement(at: progress)
        return interpolated(placed.beat, portion: placed.portion)
    }

    /// Players on the slow clock, except the player the ball is going to. A pass receiver
    /// runs onto the ball and is there when it arrives, and the shooter stays with the strike.
    func places(ballProgress: Double, playerProgress: Double) -> [HighlightPlace] {
        pose(at: playerProgress).places.map { place in
            HighlightPlace(
                id: place.id,
                point: tracked(place.id, ballProgress: ballProgress, playerProgress: playerProgress),
                role: place.role,
                attacks: place.attacks
            )
        }
    }

    /// Where the ball is drawn. Passes and shots follow `ballProgress`. A dribble stays with the
    /// slower player clock instead of racing ahead of the circle.
    func ballAnchor(ballProgress: Double, playerProgress: Double) -> PitchPoint {
        let ball = placement(at: ballProgress)
        switch ball.beat.kind {
        case .carry:
            return carryPoint(ball.beat, index: ball.index, progress: playerProgress)
        case .pass, .shot:
            let start = releasePoint(before: ball.index, ballProgress: ballProgress, playerProgress: playerProgress)
            return lerp(start, ball.beat.ballEnd, ball.portion)
        }
    }

    func ballOwner(at progress: Double) -> Int {
        placement(at: progress).beat.ballOwner
    }

    func move(for actor: Int, at progress: Double) -> HighlightMove? {
        placement(at: progress).beat.moves.first { $0.actorID == actor }
    }

    /// Where one player is drawn. A receiver who would still be short of the pass is run forward so they meet it.
    private func tracked(_ id: Int, ballProgress: Double, playerProgress: Double) -> PitchPoint {
        let ratio = ballProgress > 0.000_001 ? playerProgress / ballProgress : 1
        var progress = playerProgress
        for index in beats.indices {
            let beat = beats[index]
            let span = beatSpan(index)
            let keepsUp = (beat.kind == .pass && receiver(of: beat) == id)
                || (beat.kind == .shot && beat.ballOwner == id)
            guard keepsUp, ballProgress > span.start else { continue }
            if ballProgress >= span.end {
                progress = max(progress, span.end)
                continue
            }
            if progress >= span.start {
                progress = max(progress, ballProgress)
                continue
            }
            let from = pose(at: min(span.start * ratio, span.start)).places.first { $0.id == id }?.point
            let to = beat.moves.first { $0.actorID == id }?.end
            guard let from, let to else { continue }
            let length = span.end - span.start
            let portion = length <= 0 ? 1 : min(1, (ballProgress - span.start) / length)
            return lerp(from, to, portion)
        }
        return pose(at: min(max(progress, 0), 1)).places.first { $0.id == id }?.point
            ?? PitchPoint(x: 0.5, y: 0.5)
    }

    private func receiver(of beat: HighlightBeat) -> Int? {
        guard beat.kind == .pass else { return nil }
        let arrived = beat.moves.filter { $0.end.distance(to: beat.ballEnd) < 0.000_001 }
        return arrived.first { $0.actorID != beat.ballOwner }?.actorID ?? arrived.first?.actorID
    }

    private struct Placement {
        var beat: HighlightBeat
        var portion: Double
        var index: Int
    }

    private func placement(at progress: Double) -> Placement {
        let clamped = min(max(progress, 0), 1)
        let total = beats.reduce(0) { $0 + $1.weight }
        var remaining = clamped * total
        for (index, beat) in beats.enumerated() {
            let last = index == beats.count - 1
            if remaining <= beat.weight || last {
                let portion = beat.weight <= 0 ? 1 : min(1, remaining / beat.weight)
                return Placement(beat: beat, portion: portion, index: index)
            }
            remaining -= beat.weight
        }
        let last = beats.count - 1
        return Placement(beat: beats[last], portion: 1, index: last)
    }

    /// Player progress along a carry. Before they arrive, the ball waits at the start of the beat.
    private func carryPoint(_ beat: HighlightBeat, index: Int, progress: Double) -> PitchPoint {
        let span = beatSpan(index)
        if progress <= span.start { return beat.ballStart }
        if progress >= span.end { return beat.ballEnd }
        let length = span.end - span.start
        let portion = length <= 0 ? 1 : (progress - span.start) / length
        return lerp(beat.ballStart, beat.ballEnd, portion)
    }

    /// Where a pass or shot is struck from. A dribble releases from the slower player, not from the end of the scripted run.
    private func releasePoint(before index: Int, ballProgress: Double, playerProgress: Double) -> PitchPoint {
        guard index > 0 else { return beats[0].ballStart }
        let previous = beats[index - 1]
        switch previous.kind {
        case .carry:
            let ratio = ballProgress > 0 ? playerProgress / ballProgress : 1
            let span = beatSpan(index - 1)
            return carryPoint(previous, index: index - 1, progress: span.end * ratio)
        case .pass, .shot:
            return previous.ballEnd
        }
    }

    private func beatSpan(_ index: Int) -> (start: Double, end: Double) {
        let total = beats.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return (0, 1) }
        let prefix = beats.prefix(index).reduce(0) { $0 + $1.weight }
        let start = prefix / total
        let end = index == beats.count - 1 ? 1 : (prefix + beats[index].weight) / total
        return (start, end)
    }

    private func interpolated(_ beat: HighlightBeat, portion: Double) -> HighlightPose {
        let places = beat.moves.map { move in
            let actor = actors.first { $0.id == move.actorID }
            return HighlightPlace(
                id: move.actorID,
                point: lerp(move.start, move.end, portion),
                role: actor?.role ?? .teammate,
                attacks: actor?.attacks ?? false
            )
        }
        return HighlightPose(
            ball: lerp(beat.ballStart, beat.ballEnd, portion),
            shotProgress: beat.kind == .shot ? portion : 0,
            places: places
        )
    }

    private func lerp(_ start: PitchPoint, _ end: PitchPoint, _ portion: Double) -> PitchPoint {
        PitchPoint(
            x: start.x + (end.x - start.x) * portion,
            y: start.y + (end.y - start.y) * portion
        )
    }
}

/// Local frame for one attack. y is 0 on the goal line being attacked and 1 at the far edge of the third.
private struct LocalPoint: Equatable {
    var x: Double
    var y: Double
}

private struct ScriptBuilder {
    var shot: Shot
    var rng: SeededGenerator
    var end: PitchEnd
    var side: Double = -1
    var people: [Int: LocalPoint] = [:]
    var actors: [HighlightActor] = []
    var beats: [HighlightBeat] = []

    init(shot: Shot, matchSeed: UInt64) {
        self.shot = shot
        rng = SeededGenerator(seed: Self.scriptSeed(matchSeed: matchSeed, shot: shot))
        end = PitchEnd.attacked(byHome: shot.isHome, minute: shot.minute)
    }

    mutating func build() -> HighlightScript {
        side = coin() ? -1 : 1
        let template = pickTemplate()
        let shotFinish = chooseFinish()
        cast(template)
        switch template {
        case .wing:
            wing()
        case .throughTheMiddle:
            throughTheMiddle()
        case .counter:
            counter()
        case .oneTwo:
            oneTwo()
        case .cutback:
            cutback()
        case .penalty:
            penalty()
        }
        shoot(shotFinish)
        return HighlightScript(
            template: template,
            attackingEnd: end,
            finish: shotFinish,
            actors: actors,
            beats: beats
        )
    }

    mutating func pickTemplate() -> HighlightTemplate {
        if shot.type == .penalty {
            return .penalty
        }
        let open: [HighlightTemplate]
        if shot.passer == nil {
            open = [.wing, .throughTheMiddle, .counter, .cutback]
        } else {
            open = [.wing, .throughTheMiddle, .counter, .oneTwo, .cutback]
        }
        return open[Int(rng.next() % UInt64(open.count))]
    }

    mutating func chooseFinish() -> ShotFinish {
        switch shot.result {
        case .goal:
            return .net
        case .save:
            return .keeper
        case .miss:
            return coin() ? .wide : .over
        }
    }

    mutating func cast(_ template: HighlightTemplate) {
        add(.shooter, id: 0, attacks: true, name: shot.shooter.fullName, at: LocalPoint(x: 0.5, y: 0.7))
        add(.keeper, id: 1, attacks: false, name: shot.keeper.fullName, at: LocalPoint(x: 0.5, y: 0.06))
        add(.defender, id: 4, attacks: false, name: "Defender", at: LocalPoint(x: 0.5, y: 0.42))
        if let passer = shot.passer {
            add(.passer, id: 2, attacks: true, name: passer.fullName, at: LocalPoint(x: 0.5, y: 0.82))
        }
        let extraTeammate = template == .penalty || (template != .oneTwo && coin())
        if extraTeammate {
            add(.teammate, id: 3, attacks: true, name: "Teammate", at: LocalPoint(x: 0.32, y: 0.6))
        }
        if actors.count < 6, coin() || template == .counter {
            add(.defender, id: 5, attacks: false, name: "Defender", at: LocalPoint(x: 0.68, y: 0.5))
        }
    }

    mutating func add(_ role: HighlightActor.Role, id: Int, attacks: Bool, name: String, at point: LocalPoint) {
        actors.append(HighlightActor(id: id, role: role, attacks: attacks, name: name))
        people[id] = point
    }

    mutating func wing() {
        let wide = 0.5 + side * 0.36
        if people[2] != nil {
            place(2, LocalPoint(x: wide, y: 0.86))
            place(0, LocalPoint(x: 0.5 - side * 0.06, y: 0.64))
            place(4, LocalPoint(x: 0.5 + side * 0.08, y: 0.4))
            carry(2, to: wander(LocalPoint(x: wide, y: 0.4), radius: 0.02), weight: 1.25)
            if people[3] != nil, coin() {
                // The extra pass is before the cross. The recorded passer still plays the last one.
                place(3, LocalPoint(x: 0.5 + side * 0.16, y: 0.78))
            }
            let arrival = wander(LocalPoint(x: 0.5 - side * 0.08, y: 0.3), radius: 0.02)
            pass(from: 2, to: 0, at: arrival, weight: 0.85)
        } else {
            place(0, LocalPoint(x: wide, y: 0.82))
            place(4, LocalPoint(x: 0.5 + side * 0.1, y: 0.46))
            carry(0, to: wander(LocalPoint(x: 0.5 + side * 0.1, y: 0.32), radius: 0.02), weight: 1.35)
        }
    }

    mutating func throughTheMiddle() {
        place(4, LocalPoint(x: 0.5 + side * 0.14, y: 0.38))
        if people[5] != nil {
            place(5, LocalPoint(x: 0.5 - side * 0.16, y: 0.46))
        }
        if people[2] != nil {
            place(2, LocalPoint(x: 0.5 + side * 0.04, y: 0.88))
            place(0, LocalPoint(x: 0.5 - side * 0.08, y: 0.58))
            let arrival = wander(LocalPoint(x: 0.5 + side * 0.02, y: 0.3), radius: 0.015)
            pass(from: 2, to: 0, at: arrival, weight: 0.9)
        } else {
            place(0, LocalPoint(x: 0.48, y: 0.86))
            carry(0, to: wander(LocalPoint(x: 0.5, y: 0.32), radius: 0.02), weight: 1.2)
        }
    }

    mutating func counter() {
        place(4, LocalPoint(x: 0.5 - side * 0.2, y: 0.55))
        if people[2] != nil {
            place(2, LocalPoint(x: 0.5 + side * 0.22, y: 0.94))
            place(0, LocalPoint(x: 0.5 - side * 0.05, y: 0.72))
            carry(2, to: LocalPoint(x: 0.5 + side * 0.12, y: 0.62), weight: 0.55)
            let arrival = wander(LocalPoint(x: 0.5 + side * 0.04, y: 0.34), radius: 0.02)
            pass(from: 2, to: 0, at: arrival, weight: 0.5)
        } else {
            place(0, LocalPoint(x: 0.5 + side * 0.08, y: 0.94))
            carry(0, to: wander(LocalPoint(x: 0.5, y: 0.34), radius: 0.02), weight: 0.7)
        }
    }

    mutating func oneTwo() {
        place(0, LocalPoint(x: 0.5 - side * 0.1, y: 0.74))
        place(2, LocalPoint(x: 0.5 + side * 0.14, y: 0.58))
        place(4, LocalPoint(x: 0.5 + side * 0.02, y: 0.4))
        let layOff = wander(LocalPoint(x: 0.5 + side * 0.16, y: 0.46), radius: 0.015)
        pass(from: 0, to: 2, at: layOff, weight: 0.7)
        let returnPass = wander(LocalPoint(x: 0.5 - side * 0.02, y: 0.3), radius: 0.015)
        pass(from: 2, to: 0, at: returnPass, weight: 0.65)
    }

    mutating func cutback() {
        let byline = LocalPoint(x: 0.5 + side * 0.4, y: 0.12)
        place(4, LocalPoint(x: 0.5 + side * 0.08, y: 0.36))
        if people[2] != nil {
            place(2, LocalPoint(x: 0.5 + side * 0.32, y: 0.7))
            place(0, LocalPoint(x: 0.5 - side * 0.06, y: 0.55))
            carry(2, to: wander(byline, radius: 0.015), weight: 1.15)
            let arrival = wander(LocalPoint(x: 0.5 + side * 0.02, y: 0.28), radius: 0.015)
            pass(from: 2, to: 0, at: arrival, weight: 0.8)
        } else {
            place(0, LocalPoint(x: 0.5 + side * 0.3, y: 0.72))
            carry(0, to: wander(LocalPoint(x: byline.x, y: 0.2), radius: 0.015), weight: 1.2)
        }
    }

    mutating func penalty() {
        place(0, LocalPoint(x: 0.5, y: 0.4))
        place(1, LocalPoint(x: 0.5, y: 0.05))
        place(4, LocalPoint(x: 0.74, y: 0.62))
        if people[3] != nil {
            place(3, LocalPoint(x: 0.26, y: 0.62))
        }
        carry(0, to: LocalPoint(x: 0.5, y: PitchGeometry.spotLocal), weight: 0.7)
    }

    mutating func shoot(_ finish: ShotFinish) {
        let target = target(finish)
        var ends: [Int: LocalPoint] = [:]
        let shooter = people[0] ?? LocalPoint(x: 0.5, y: 0.3)
        ends[0] = LocalPoint(x: shooter.x + side * 0.01, y: max(0.18, shooter.y - 0.04))
        if finish == .keeper {
            ends[1] = target
        } else if finish == .net {
            ends[1] = clampKeeper(LocalPoint(x: 0.5 - side * 0.08, y: 0.05))
        } else {
            ends[1] = clampKeeper(LocalPoint(x: 0.5 + side * 0.03, y: 0.055))
        }
        for actor in actors where actor.role == .defender {
            ends[actor.id] = close(from: people[actor.id] ?? LocalPoint(x: 0.5, y: 0.4), toward: target)
        }
        beat(.shot, weight: timing(1), from: 0, ballEnd: target, ends: ends)
    }

    mutating func target(_ finish: ShotFinish) -> LocalPoint {
        switch finish {
        case .net:
            let offset = 0.012 + unit() * 0.02
            return LocalPoint(x: 0.5 + side * offset, y: 0)
        case .wide:
            let offset = PitchGeometry.displayGoalHalfWidth + 0.07 + unit() * 0.06
            return LocalPoint(x: 0.5 + side * offset, y: 0.02)
        case .over:
            let offset = PitchGeometry.displayGoalHalfWidth + 0.03 + unit() * 0.02
            return LocalPoint(x: 0.5 + side * offset, y: 0.012)
        case .keeper:
            return clampKeeper(LocalPoint(x: 0.5 + side * (0.03 + unit() * 0.05), y: 0.045 + unit() * 0.04))
        }
    }

    mutating func carry(_ id: Int, to end: LocalPoint, weight: Double) {
        var ends: [Int: LocalPoint] = [id: end]
        support(into: &ends, ball: end, holding: id)
        beat(.carry, weight: timing(weight), from: id, ballEnd: end, ends: ends)
    }

    mutating func pass(from passer: Int, to receiver: Int, at arrival: LocalPoint, weight: Double) {
        var ends: [Int: LocalPoint] = [
            receiver: arrival,
            passer: people[passer] ?? arrival
        ]
        support(into: &ends, ball: arrival, holding: receiver)
        beat(.pass, weight: timing(weight), from: passer, ballEnd: arrival, ends: ends)
    }

    mutating func support(into ends: inout [Int: LocalPoint], ball: LocalPoint, holding: Int) {
        for actor in actors where actor.role == .defender {
            ends[actor.id] = close(from: people[actor.id] ?? ball, toward: ball)
        }
        if let keeper = people[1] {
            ends[1] = keeper
        }
        if let teammate = people[3], holding != 3, ends[3] == nil {
            ends[3] = LocalPoint(x: min(max(teammate.x + side * 0.02, 0.12), 0.88), y: max(0.34, teammate.y - 0.06))
        }
    }

    mutating func beat(
        _ kind: HighlightBeat.Kind,
        weight: Double,
        from owner: Int,
        ballEnd: LocalPoint,
        ends: [Int: LocalPoint]
    ) {
        let ballStart = people[owner] ?? ballEnd
        var moves: [HighlightMove] = []
        var next = people
        for id in people.keys.sorted() {
            let start = people[id] ?? ballStart
            let localEnd = clamped(id, ends[id] ?? start)
            moves.append(HighlightMove(actorID: id, start: absolute(start), end: absolute(localEnd)))
            next[id] = localEnd
        }
        people = next
        beats.append(
            HighlightBeat(
                kind: kind,
                weight: weight,
                ballOwner: owner,
                ballStart: absolute(ballStart),
                ballEnd: absolute(ballEnd),
                moves: moves
            )
        )
    }

    func clamped(_ id: Int, _ point: LocalPoint) -> LocalPoint {
        if actors.first(where: { $0.id == id })?.role == .keeper {
            return clampKeeper(point)
        }
        return clampOutfield(point)
    }

    func clampOutfield(_ point: LocalPoint) -> LocalPoint {
        LocalPoint(x: min(max(point.x, 0.06), 0.94), y: min(max(point.y, 0.08), 0.96))
    }

    func clampKeeper(_ point: LocalPoint) -> LocalPoint {
        let half = PitchGeometry.sixHalfWidth - 0.02
        let yMax = PitchGeometry.sixDepthLocal - 0.02
        return LocalPoint(
            x: min(max(point.x, 0.5 - half), 0.5 + half),
            y: min(max(point.y, 0.03), yMax)
        )
    }

    func close(from start: LocalPoint, toward ball: LocalPoint) -> LocalPoint {
        let dx = ball.x - start.x
        let dy = ball.y - start.y
        let distance = (dx * dx + dy * dy).squareRoot()
        let minimum = 0.12
        if distance <= minimum {
            return clampOutfield(start)
        }
        let travel = min(distance * 0.5, distance - minimum)
        let next = LocalPoint(x: start.x + dx / distance * travel, y: start.y + dy / distance * travel)
        let clamped = clampOutfield(next)
        let left = (clamped.x - ball.x) * (clamped.x - ball.x) + (clamped.y - ball.y) * (clamped.y - ball.y)
        if left.squareRoot() < minimum - 0.01 {
            return clampOutfield(start)
        }
        return clamped
    }

    mutating func place(_ id: Int, _ point: LocalPoint) {
        guard people[id] != nil else { return }
        people[id] = clamped(id, point)
    }

    mutating func wander(_ point: LocalPoint, radius: Double) -> LocalPoint {
        let x = point.x + (unit() - 0.5) * 2 * radius
        let y = point.y + (unit() - 0.5) * 2 * radius
        return clampOutfield(LocalPoint(x: x, y: y))
    }

    mutating func timing(_ base: Double) -> Double {
        base * (0.82 + unit() * 0.36)
    }

    mutating func unit() -> Double {
        Double(rng.next() % 10_000) / 9_999
    }

    mutating func coin() -> Bool {
        rng.next() & 1 == 0
    }

    func absolute(_ local: LocalPoint) -> PitchPoint {
        let along = local.y * PitchGeometry.playDepth
        switch end {
        case .north:
            return PitchPoint(x: local.x, y: along)
        case .south:
            return PitchPoint(x: local.x, y: 1 - along)
        }
    }

    /// Minute is left out on purpose. The half maps the same move onto the other goal.
    static func scriptSeed(matchSeed: UInt64, shot: Shot) -> UInt64 {
        var mixed = matchSeed &+ 0x9E37_79B9_7F4A_7C15
        mixed ^= UInt64(bitPattern: Int64(shot.id)) &* 0xBF58_476D_1CE4_E5B9
        mixed ^= shot.isHome ? 0xA5A5_A5A5_A5A5_A5A5 : 0x5A5A_5A5A_5A5A_5A5A
        switch shot.result {
        case .goal:
            mixed ^= 0x1111_1111_1111_1111
        case .save:
            mixed ^= 0x2222_2222_2222_2222
        case .miss:
            mixed ^= 0x3333_3333_3333_3333
        }
        if shot.type == .penalty {
            mixed ^= 0x4444_4444_4444_4444
        }
        if shot.passer != nil {
            mixed ^= 0x5555_5555_5555_5555
        }
        return mixed == 0 ? 1 : mixed
    }
}
