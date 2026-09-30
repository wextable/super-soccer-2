import SwiftUI

/// Attacking-third camera. The goal being attacked is at the top. Grass, markings, and figures are drawn, not traced.
struct PitchView: View {
    var script: HighlightScript?
    var progress: Double
    var attackingEnd: PitchEnd
    var attackingShirt: Color
    var attackingShorts: Color
    var defendingShirt: Color
    var defendingShorts: Color
    var minute: String

    @Environment(\.theme) private var theme

    var body: some View {
        Color.clear
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                Canvas { context, size in
                    drawPitch(in: &context, size: size)
                }
            }
            .overlay(alignment: .bottomLeading) {
                minuteMark
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.pitchRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    private var minuteMark: some View {
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

    private func drawPitch(in context: inout GraphicsContext, size: CGSize) {
        let frame = PitchFrame(size: size)
        let pose = script?.pose(at: progress)
        drawGrass(in: &context, size: size)
        drawGoalShadow(in: &context, frame: frame)
        drawGoal(in: &context, frame: frame)
        drawMarkings(in: &context, frame: frame)
        drawFlags(in: &context, frame: frame)
        guard let pose, let script else { return }
        let running = progress < 0.985
        for place in pose.places {
            let point = frame.screen(place.point, end: attackingEnd)
            drawShadow(in: &context, at: point, scale: place.role == .keeper ? 1.15 : 1, size: size)
        }
        for place in pose.places {
            let point = frame.screen(place.point, end: attackingEnd)
            let frameIndex = running ? (Int(progress * 24) + place.id) % 3 : 1
            drawPlayer(
                in: &context,
                at: point,
                place: place,
                frame: frameIndex,
                size: size
            )
        }
        var ball = frame.screen(pose.ball, end: attackingEnd)
        if script.finish == .over {
            ball.y -= CGFloat(pose.shotProgress) * size.height * 0.14
        }
        drawBall(in: &context, at: ball, spin: progress * .pi * 4, size: size)
    }

    private func drawGrass(in context: inout GraphicsContext, size: CGSize) {
        let deep = Color(red: 0.04, green: 0.24, blue: 0.10)
        let band = theme.colors.pitch.color
        let count = 8
        let height = size.height / CGFloat(count)
        for index in 0..<count {
            let rect = CGRect(x: 0, y: CGFloat(index) * height, width: size.width, height: height + 0.5)
            context.fill(Path(rect), with: .color(index.isMultiple(of: 2) ? deep : band))
        }
    }

    private func drawGoalShadow(in context: inout GraphicsContext, frame: PitchFrame) {
        let mouth = frame.screen(0.5 + PitchGeometry.goalHalfWidth, 0)
        let rect = CGRect(x: mouth.x + 6, y: mouth.y + 3, width: frame.size.width * 0.055, height: frame.size.height * 0.018)
        context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.38)))
    }

    private func drawGoal(in context: inout GraphicsContext, frame: PitchFrame) {
        let left = frame.screen(0.5 - PitchGeometry.goalHalfWidth, 0)
        let right = frame.screen(0.5 + PitchGeometry.goalHalfWidth, 0)
        let rise = frame.size.height * 0.105
        let frontLeft = CGPoint(x: left.x, y: left.y - rise)
        let frontRight = CGPoint(x: right.x, y: right.y - rise)
        let inset = (right.x - left.x) * 0.16
        let backRise = rise * 0.62
        let backLeft = CGPoint(x: left.x + inset, y: frontLeft.y - backRise)
        let backRight = CGPoint(x: right.x - inset, y: frontRight.y - backRise)
        let backFootLeft = CGPoint(x: left.x + inset * 0.35, y: left.y - rise * 0.08)
        let backFootRight = CGPoint(x: right.x - inset * 0.35, y: right.y - rise * 0.08)

        var net = Path()
        net.move(to: left)
        net.addLine(to: frontLeft)
        net.addLine(to: backLeft)
        net.addLine(to: backRight)
        net.addLine(to: frontRight)
        net.addLine(to: right)
        net.addLine(to: backFootRight)
        net.addLine(to: backFootLeft)
        net.closeSubpath()
        context.fill(net, with: .color(.white.opacity(0.16)))

        var mesh = Path()
        for step in 1...3 {
            let t = CGFloat(step) / 4
            mesh.move(to: mix(frontLeft, backLeft, t))
            mesh.addLine(to: mix(frontRight, backRight, t))
            mesh.move(to: mix(left, backFootLeft, t))
            mesh.addLine(to: mix(frontLeft, backLeft, t))
            mesh.move(to: mix(right, backFootRight, t))
            mesh.addLine(to: mix(frontRight, backRight, t))
        }
        context.stroke(mesh, with: .color(.white.opacity(0.45)), lineWidth: 1)

        var posts = Path()
        posts.move(to: left)
        posts.addLine(to: frontLeft)
        posts.addLine(to: frontRight)
        posts.addLine(to: right)
        context.stroke(posts, with: .color(theme.colors.pitchLine.color), lineWidth: theme.metrics.pitchLine + 1)
    }

    private func drawMarkings(in context: inout GraphicsContext, frame: PitchFrame) {
        let ink = theme.colors.pitchLine.color
        let line = theme.metrics.pitchLine
        var bounds = Path()
        bounds.move(to: frame.screen(0, 0))
        bounds.addLine(to: frame.screen(1, 0))
        bounds.addLine(to: frame.screen(1, 1))
        bounds.move(to: frame.screen(0, 0))
        bounds.addLine(to: frame.screen(0, 1))
        context.stroke(bounds, with: .color(ink), lineWidth: line)

        strokeBox(
            halfWidth: PitchGeometry.boxHalfWidth,
            depth: PitchGeometry.boxDepthLocal,
            in: &context,
            frame: frame
        )
        strokeBox(
            halfWidth: PitchGeometry.sixHalfWidth,
            depth: PitchGeometry.sixDepthLocal,
            in: &context,
            frame: frame
        )

        let spot = frame.screen(0.5, PitchGeometry.spotLocal)
        let dot = CGRect(x: spot.x - 2, y: spot.y - 2, width: 4, height: 4)
        context.fill(Path(ellipseIn: dot), with: .color(ink))
        context.stroke(penaltyArc(frame), with: .color(ink), lineWidth: line)
        context.stroke(cornerArc(left: true, frame: frame), with: .color(ink), lineWidth: line)
        context.stroke(cornerArc(left: false, frame: frame), with: .color(ink), lineWidth: line)
    }

    private func strokeBox(halfWidth: Double, depth: Double, in context: inout GraphicsContext, frame: PitchFrame) {
        var path = Path()
        path.move(to: frame.screen(0.5 - halfWidth, 0))
        path.addLine(to: frame.screen(0.5 - halfWidth, depth))
        path.addLine(to: frame.screen(0.5 + halfWidth, depth))
        path.addLine(to: frame.screen(0.5 + halfWidth, 0))
        context.stroke(path, with: .color(theme.colors.pitchLine.color), lineWidth: theme.metrics.pitchLine)
    }

    private func penaltyArc(_ frame: PitchFrame) -> Path {
        var path = Path()
        let spotY = PitchGeometry.spotLocal
        var started = false
        for index in 0...18 {
            let angle = Double.pi * Double(index) / 18
            let x = 0.5 + cos(angle) * PitchGeometry.arcRadiusX
            let y = spotY + sin(angle) * PitchGeometry.arcRadiusLocalY
            guard y >= PitchGeometry.boxDepthLocal - 0.004 else { continue }
            let point = frame.screen(x, y)
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
        }
        return path
    }

    private func cornerArc(left: Bool, frame: PitchFrame) -> Path {
        var path = Path()
        let radiusX = PitchGeometry.cornerRadiusX
        let radiusY = PitchGeometry.cornerRadiusLocalY
        for index in 0...6 {
            let angle = (Double.pi / 2) * Double(index) / 6
            let x = left ? radiusX * sin(angle) : 1 - radiusX * sin(angle)
            let y = radiusY * cos(angle)
            let point = frame.screen(x, y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }

    private func drawFlags(in context: inout GraphicsContext, frame: PitchFrame) {
        plantFlag(at: frame.screen(0, 0), lean: 1, in: &context, frame: frame)
        plantFlag(at: frame.screen(1, 0), lean: -1, in: &context, frame: frame)
    }

    private func plantFlag(at foot: CGPoint, lean: CGFloat, in context: inout GraphicsContext, frame: PitchFrame) {
        let height = frame.size.height * 0.075
        let tip = CGPoint(x: foot.x, y: foot.y - height)
        var pole = Path()
        pole.move(to: foot)
        pole.addLine(to: tip)
        context.stroke(pole, with: .color(theme.colors.pitchLine.color), lineWidth: 2)
        var flag = Path()
        flag.move(to: tip)
        flag.addLine(to: CGPoint(x: tip.x + lean * frame.size.width * 0.045, y: tip.y + height * 0.18))
        flag.addLine(to: CGPoint(x: tip.x, y: tip.y + height * 0.38))
        flag.closeSubpath()
        context.fill(flag, with: .color(attackingShirt))
        context.stroke(flag, with: .color(.black.opacity(0.45)), lineWidth: 1)
    }

    private func drawShadow(in context: inout GraphicsContext, at foot: CGPoint, scale: CGFloat, size: CGSize) {
        let width = size.width * 0.045 * scale
        let rect = CGRect(x: foot.x - width * 0.55, y: foot.y - width * 0.12, width: width * 1.1, height: width * 0.28)
        context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.35)))
    }

    private func drawPlayer(
        in context: inout GraphicsContext,
        at foot: CGPoint,
        place: HighlightPlace,
        frame: Int,
        size: CGSize
    ) {
        let keeper = place.role == .keeper
        let scale: CGFloat = keeper ? 1.18 : 1
        let width = size.width * 0.052 * scale
        let shirt = keeper ? defendingShorts : (place.attacks ? attackingShirt : defendingShirt)
        let shorts = keeper ? defendingShirt : (place.attacks ? attackingShorts : defendingShorts)
        let outline = Color.black.opacity(0.72)
        let skin = Color(red: 0.96, green: 0.76, blue: 0.58)
        let step: CGFloat = frame == 1 ? 0 : (frame == 0 ? width * 0.42 : -width * 0.42)
        let swing: CGFloat = frame == 1 ? 0.15 : (frame == 0 ? -0.9 : 0.9)

        let leftFoot = CGPoint(x: foot.x - width * 0.22 + step, y: foot.y)
        let rightFoot = CGPoint(x: foot.x + width * 0.22 - step, y: foot.y - abs(step) * 0.15)
        fillFoot(leftFoot, width: width, in: &context, outline: outline)
        fillFoot(rightFoot, width: width, in: &context, outline: outline)

        let hip = CGPoint(x: foot.x, y: foot.y - width * 0.55)
        let shortsRect = CGRect(x: hip.x - width * 0.42, y: hip.y - width * 0.08, width: width * 0.84, height: width * 0.46)
        context.fill(Path(roundedRect: shortsRect, cornerRadius: width * 0.12), with: .color(shorts))
        context.stroke(Path(roundedRect: shortsRect, cornerRadius: width * 0.12), with: .color(outline), lineWidth: 1)

        let chest = CGPoint(x: foot.x, y: foot.y - width * 1.2)
        let torso = CGRect(x: chest.x - width * 0.5, y: chest.y - width * 0.5, width: width, height: width)
        context.fill(Path(ellipseIn: torso), with: .color(shirt))
        context.stroke(Path(ellipseIn: torso), with: .color(outline), lineWidth: 1)

        let shoulder = CGPoint(x: chest.x, y: chest.y - width * 0.05)
        if keeper {
            drawLimb(from: shoulder, angle: .pi * 0.15, length: width * 0.95, in: &context, width: width * 0.16, outline: outline, skin: skin, glove: true)
            drawLimb(from: shoulder, angle: .pi * 0.85, length: width * 0.95, in: &context, width: width * 0.16, outline: outline, skin: skin, glove: true)
        } else {
            drawLimb(from: shoulder, angle: swing, length: width * 0.85, in: &context, width: width * 0.14, outline: outline, skin: skin, glove: false)
            drawLimb(from: shoulder, angle: .pi - swing, length: width * 0.85, in: &context, width: width * 0.14, outline: outline, skin: skin, glove: false)
        }

        let headCenter = CGPoint(x: foot.x, y: foot.y - width * 2.05)
        let head = CGRect(x: headCenter.x - width * 0.4, y: headCenter.y - width * 0.4, width: width * 0.8, height: width * 0.8)
        context.fill(Path(ellipseIn: head), with: .color(skin))
        context.stroke(Path(ellipseIn: head), with: .color(outline), lineWidth: 1)
        let hair = CGRect(x: head.minX - width * 0.02, y: head.minY - width * 0.06, width: head.width * 1.05, height: head.height * 0.48)
        context.fill(Path(ellipseIn: hair), with: .color(.black.opacity(0.82)))
        let eyeY = headCenter.y - width * 0.02
        for side in [-1.0, 1.0] as [CGFloat] {
            let eye = CGRect(x: headCenter.x + side * width * 0.12 - 1, y: eyeY, width: 2.2, height: 2.2)
            context.fill(Path(ellipseIn: eye), with: .color(.black))
        }
    }

    private func fillFoot(_ center: CGPoint, width: CGFloat, in context: inout GraphicsContext, outline: Color) {
        let rect = CGRect(x: center.x - width * 0.16, y: center.y - width * 0.1, width: width * 0.32, height: width * 0.18)
        context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.85)))
        context.stroke(Path(ellipseIn: rect), with: .color(outline), lineWidth: 0.5)
    }

    private func drawLimb(
        from start: CGPoint,
        angle: CGFloat,
        length: CGFloat,
        in context: inout GraphicsContext,
        width: CGFloat,
        outline: Color,
        skin: Color,
        glove: Bool
    ) {
        let end = CGPoint(
            x: start.x + CGFloat(cos(Double(angle))) * length,
            y: start.y + CGFloat(sin(Double(angle))) * length
        )
        var arm = Path()
        arm.move(to: start)
        arm.addLine(to: end)
        context.stroke(arm, with: .color(outline), lineWidth: width)
        let hand = CGRect(x: end.x - width, y: end.y - width, width: width * 2, height: width * 2)
        context.fill(Path(ellipseIn: hand), with: .color(glove ? theme.colors.pitchLine.color : skin))
    }

    private func drawBall(in context: inout GraphicsContext, at center: CGPoint, spin: Double, size: CGSize) {
        let radius = max(4, size.width * 0.026)
        let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: bounds), with: .color(.white))
        context.stroke(Path(ellipseIn: bounds), with: .color(.black), lineWidth: 1)
        var patch = Path()
        for index in 0..<5 {
            let angle = spin + Double(index) * (2 * .pi / 5) - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * 0.48,
                y: center.y + CGFloat(sin(angle)) * radius * 0.48
            )
            if index == 0 {
                patch.move(to: point)
            } else {
                patch.addLine(to: point)
            }
        }
        patch.closeSubpath()
        context.fill(patch, with: .color(.black))
    }

    private func mix(_ start: CGPoint, _ end: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
    }
}

private struct PitchFrame {
    var size: CGSize

    var top: CGFloat { size.height * 0.17 }
    var bottom: CGFloat { size.height * 0.96 }
    var left: CGFloat { size.width * 0.08 }
    var right: CGFloat { size.width * 0.92 }

    func screen(_ localX: Double, _ localY: Double) -> CGPoint {
        CGPoint(
            x: left + (right - left) * localX,
            y: top + (bottom - top) * localY
        )
    }

    func screen(_ point: PitchPoint, end: PitchEnd) -> CGPoint {
        let local = point.inAttackingView(of: end)
        return screen(local.x, min(max(local.y, -0.02), 1.05))
    }
}
