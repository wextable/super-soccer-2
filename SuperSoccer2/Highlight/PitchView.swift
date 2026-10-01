import SwiftUI

/// Flat grass, simple lines, the old player tokens, and the plain ball.
/// North is the bottom of the screen and south is the top, so the goal switches ends with possession.
/// A local clock samples the script, because a store progress of 0 then 1 does not interpolate a computed point.
/// Players take longer than the ball.
struct PitchView: View {
    var script: HighlightScript?
    var progress: Double
    var attackingEnd: PitchEnd
    var attacking: KitColor
    var defending: KitColor
    var minute: String
    /// True while the move should play from the start of the script to the end.
    var animated: Bool

    @Environment(\.theme) private var theme
    @State private var playStart: Date?

    /// Fits inside the line hold so the final frame sits before the next shot.
    private static let ballSeconds = 1.6
    /// A bit slower than the ball, and still finished before the line hold ends.
    private static let playerSeconds = 2.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            let speeds = displayedProgress(now: timeline.date)
            field(ballProgress: speeds.ball, playerProgress: speeds.players)
        }
        .onChange(of: animated) { _, isAnimated in
            playStart = isAnimated ? Date() : nil
        }
        .onChange(of: script) { _, newScript in
            playStart = animated && newScript != nil ? Date() : nil
        }
        .onAppear {
            if animated, playStart == nil {
                playStart = Date()
            }
        }
    }

    private func displayedProgress(now: Date) -> (ball: Double, players: Double) {
        guard animated else { return (progress, progress) }
        guard let playStart else { return (0, 0) }
        let elapsed = now.timeIntervalSince(playStart)
        return (
            min(1, elapsed / Self.ballSeconds),
            min(1, elapsed / Self.playerSeconds)
        )
    }

    private func field(ballProgress: Double, playerProgress: Double) -> some View {
        let players = script?.pose(at: playerProgress)
        return Color.clear
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.metrics.pitchRadius, style: .continuous)
                            .fill(theme.colors.pitch.color)
                        RoundedRectangle(cornerRadius: theme.metrics.pitchRadius, style: .continuous)
                            .stroke(theme.colors.pitchLine.color, lineWidth: theme.metrics.pitchLine)
                        Rectangle()
                            .fill(theme.colors.pitchLine.color)
                            .frame(height: theme.metrics.pitchLine)
                        Circle()
                            .stroke(theme.colors.pitchLine.color, lineWidth: theme.metrics.pitchLine)
                            .frame(width: size.width * 0.28, height: size.width * 0.28)
                        RoundedRectangle(cornerRadius: theme.metrics.shadowRadius, style: .continuous)
                            .stroke(theme.colors.pitchLine.color, lineWidth: theme.metrics.pitchLine)
                            .frame(width: size.width * 0.5, height: size.height * 0.16)
                            .position(x: size.width * 0.5, y: size.height * (goalAtBottom ? 0.92 : 0.08))
                        goal(in: size)
                        if let script, let players {
                            ForEach(players.places) { place in
                                token(
                                    at: point(place.point, in: size),
                                    shirt: place.attacks ? attacking : defending,
                                    in: size
                                )
                            }
                            Circle()
                                .fill(theme.colors.pitchLine.color)
                                .overlay(Circle().stroke(theme.colors.tickerBackground.color, lineWidth: theme.metrics.hairline))
                                .frame(
                                    width: max(theme.metrics.ballMinimum, size.width * 0.035),
                                    height: max(theme.metrics.ballMinimum, size.width * 0.035)
                                )
                                .position(ballPosition(in: script, ballProgress: ballProgress, playerProgress: playerProgress, size: size))
                        }
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    Text(minute)
                        .offset(x: 1, y: 1)
                        .foregroundStyle(.black)
                    Text(minute)
                        .foregroundStyle(theme.colors.pitchLine.color)
                }
                .font(theme.type.minute)
                .padding(theme.space.sm)
                .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.pitchRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    /// North is the bottom of the screen. South is the top.
    private var goalAtBottom: Bool { attackingEnd == .north }

    private func goal(in size: CGSize) -> some View {
        let thickness = max(5, theme.metrics.pitchLine * 2.5)
        let inset = theme.metrics.pitchLine
        let y = goalAtBottom
            ? size.height - inset - thickness / 2
            : inset + thickness / 2
        return Rectangle()
            .fill(theme.colors.pitchLine.color)
            .frame(width: size.width * PitchGeometry.displayGoalHalfWidth * 2, height: thickness)
            .position(x: size.width * 0.5, y: y)
    }

    private func token(at center: CGPoint, shirt: KitColor, in size: CGSize) -> some View {
        let token = tokenSize(in: size)
        let mark = PitchPlayerIcon.image(shirt: shirt)
        return Group {
            if let mark {
                Image(uiImage: mark)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: token.width, height: token.height)
            } else {
                Circle()
                    .fill(shirt.color)
                    .frame(width: token.height, height: token.height)
            }
        }
        .position(center)
    }

    private func tokenSize(in size: CGSize) -> CGSize {
        let width = size.width * 0.09
        return CGSize(width: width, height: width * 0.5)
    }

    private func ballPosition(
        in script: HighlightScript,
        ballProgress: Double,
        playerProgress: Double,
        size: CGSize
    ) -> CGPoint {
        let anchor = script.ballAnchor(ballProgress: ballProgress, playerProgress: playerProgress)
        let ball = point(anchor, in: size)
        let ownerID = script.ballOwner(at: ballProgress)
        guard let owner = script.pose(at: playerProgress).places.first(where: { $0.id == ownerID }) else {
            return ball
        }
        let player = point(owner.point, in: size)
        let ballRadius = max(theme.metrics.ballMinimum, size.width * 0.035) / 2
        let dx = ball.x - player.x
        let dy = ball.y - player.y
        let distance = hypot(dx, dy)
        let direction: CGPoint
        if distance > 1 {
            direction = CGPoint(x: dx / distance, y: dy / distance)
        } else {
            direction = facing(of: ownerID, in: script, at: playerProgress, size: size)
        }
        let gap = tokenRadius(along: direction, in: size) + ballRadius + theme.metrics.pitchLine
        guard distance < gap else { return ball }
        return CGPoint(x: player.x + direction.x * gap, y: player.y + direction.y * gap)
    }

    /// Half the token, measured along the direction the ball is leaving.
    private func tokenRadius(along direction: CGPoint, in size: CGSize) -> CGFloat {
        let token = tokenSize(in: size)
        let rx = token.width / 2
        let ry = token.height / 2
        let denom = hypot(ry * direction.x, rx * direction.y)
        guard denom > 0.001 else { return rx }
        return (rx * ry) / denom
    }

    private func facing(of owner: Int, in script: HighlightScript, at progress: Double, size: CGSize) -> CGPoint {
        let towardGoal = goalAtBottom ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: -1)
        guard let move = script.move(for: owner, at: progress) else { return towardGoal }
        let start = point(move.start, in: size)
        let end = point(move.end, in: size)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.5 else { return towardGoal }
        return CGPoint(x: dx / length, y: dy / length)
    }

    private func point(_ pitch: PitchPoint, in size: CGSize) -> CGPoint {
        let local = pitch.inAttackingView(of: attackingEnd)
        let x = min(max(local.x, 0), 1)
        let y = min(max(local.y, 0), 1)
        return CGPoint(x: size.width * x, y: size.height * y)
    }
}
