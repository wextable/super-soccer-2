import SwiftUI

/// The old pitch: flat grass, simple lines, colored circles, and the plain ball.
/// Positions come from the script. A local clock samples that path, because a store
/// progress of 0 then 1 does not interpolate a Canvas or a computed point.
struct PitchView: View {
    var script: HighlightScript?
    var progress: Double
    var attackingEnd: PitchEnd
    var attacking: Color
    var defending: Color
    var minute: String
    /// True while the move should play from the start of the script to the end.
    var animated: Bool

    @Environment(\.theme) private var theme
    @State private var playStart: Date?

    /// Fits inside the line hold so the final frame sits before the next shot.
    private static let playSeconds = 1.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            field(at: displayedProgress(now: timeline.date))
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

    private func displayedProgress(now: Date) -> Double {
        guard animated else { return progress }
        guard let playStart else { return 0 }
        return min(1, now.timeIntervalSince(playStart) / Self.playSeconds)
    }

    private func field(at progress: Double) -> some View {
        let pose = script?.pose(at: progress)
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
                            .position(x: size.width * 0.5, y: size.height * 0.08)
                        if let pose {
                            ForEach(pose.places) { place in
                                dot(
                                    at: point(place.point, in: size),
                                    color: place.attacks ? attacking : defending,
                                    diameter: size.width * 0.05
                                )
                            }
                            Circle()
                                .fill(theme.colors.pitchLine.color)
                                .overlay(Circle().stroke(theme.colors.tickerBackground.color, lineWidth: theme.metrics.hairline))
                                .frame(
                                    width: max(theme.metrics.ballMinimum, size.width * 0.035),
                                    height: max(theme.metrics.ballMinimum, size.width * 0.035)
                                )
                                .position(point(pose.ball, in: size))
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

    private func dot(at center: CGPoint, color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(theme.colors.pitchLine.color, lineWidth: theme.metrics.pitchLine))
            .frame(width: diameter, height: diameter)
            .position(center)
    }

    private func point(_ pitch: PitchPoint, in size: CGSize) -> CGPoint {
        let local = pitch.inAttackingView(of: attackingEnd)
        let x = min(max(local.x, 0), 1)
        let y = min(max(local.y, 0), 1)
        return CGPoint(x: size.width * x, y: size.height * y)
    }
}
