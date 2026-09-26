import SwiftUI

struct PitchView: View {
    var progress: Double
    var attacking: Color
    var defending: Color
    var showsPasser: Bool
    var result: ShotResult

    @Environment(\.theme) private var theme

    var body: some View {
        Color.clear
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
                        dot(at: point(0.50, 0.16, in: size), color: defending, diameter: size.width * 0.055)
                        if showsPasser {
                            dot(at: point(0.36, 0.80, in: size), color: attacking, diameter: size.width * 0.05)
                        }
                        dot(at: point(0.60, 0.64, in: size), color: attacking, diameter: size.width * 0.055)
                        Circle()
                            .fill(theme.colors.pitchLine.color)
                            .overlay(Circle().stroke(theme.colors.tickerBackground.color, lineWidth: theme.metrics.hairline))
                            .frame(
                                width: max(theme.metrics.ballMinimum, size.width * 0.035),
                                height: max(theme.metrics.ballMinimum, size.width * 0.035)
                            )
                            .position(ballPoint(in: size))
                    }
                }
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

    private func ballPoint(in size: CGSize) -> CGPoint {
        let start = showsPasser ? point(0.36, 0.80, in: size) : point(0.60, 0.64, in: size)
        let end: CGPoint
        switch result {
        case .goal:
            end = point(0.50, 0.06, in: size)
        case .save:
            end = point(0.50, 0.16, in: size)
        case .miss:
            end = point(0.10, 0.20, in: size)
        }
        return CGPoint(
            x: start.x + (end.x - start.x) * progress,
            y: start.y + (end.y - start.y) * progress
        )
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }
}
