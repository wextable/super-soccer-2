import SwiftUI

struct PitchView: View {
    var progress: Double
    var attacking: Color
    var defending: Color
    var showsPasser: Bool
    var result: ShotResult

    var body: some View {
        Color.clear
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.pitch)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.pitchLine, lineWidth: 2)
                        Rectangle()
                            .fill(Theme.pitchLine)
                            .frame(height: 2)
                        Circle()
                            .stroke(Theme.pitchLine, lineWidth: 2)
                            .frame(width: size.width * 0.28, height: size.width * 0.28)
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Theme.pitchLine, lineWidth: 2)
                            .frame(width: size.width * 0.5, height: size.height * 0.16)
                            .position(x: size.width * 0.5, y: size.height * 0.08)
                        dot(at: point(0.50, 0.16, in: size), color: defending, diameter: size.width * 0.055)
                        if showsPasser {
                            dot(at: point(0.36, 0.80, in: size), color: attacking, diameter: size.width * 0.05)
                        }
                        dot(at: point(0.60, 0.64, in: size), color: attacking, diameter: size.width * 0.055)
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(Theme.tickerBackground, lineWidth: 1))
                            .frame(width: max(10, size.width * 0.035), height: max(10, size.width * 0.035))
                            .position(ballPoint(in: size))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private func dot(at center: CGPoint, color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
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
