import SwiftUI

/// The old post-shot celebration, in milliseconds so the hold and the picture share one clock.
enum GoalCelebrationTiming {
    /// The ball is in the net. Matches the pitch ball clock.
    static let ballMilliseconds = 1_600
    /// The word waits a beat, then springs in.
    static let wordDelay = 200
    static let wordSpring = 1_250
    /// The scorer's card fades in once the word has landed.
    static let cardFade = 300
    /// How long the name and face stay up. The old post-shot pause.
    static let hold = 2_000
    static let fadeOut = 1_000

    static var shownMilliseconds: Int {
        ballMilliseconds + wordDelay + wordSpring + cardFade + hold + fadeOut
    }

    static var ballSeconds: Double { Double(ballMilliseconds) / 1_000 }

    static func seconds(_ milliseconds: Int) -> Double {
        Double(milliseconds) / 1_000
    }
}

/// Underdamped pop, damping 0.35, the same spring the old GOAL word used.
enum GoalPop {
    static func scale(seconds: Double) -> Double {
        guard seconds > 0 else { return 0 }
        let zeta = 0.35
        let wn = 8.9
        let wd = wn * (1 - zeta * zeta).squareRoot()
        let decay = exp(-zeta * wn * seconds)
        let raw = 1 - decay * (cos(wd * seconds) + (zeta * wn / wd) * sin(wd * seconds))
        return max(0, raw)
    }
}

/// GOAL springs onto the pitch, then the scorer's face, name, and crest.
struct GoalCelebration: View {
    var name: String
    var face: PlayerFace
    var position: Position
    var clubID: String
    /// Reduce motion shows the card at rest. The spring is the animated path.
    var animated: Bool

    @Environment(\.theme) private var theme
    @State private var started: Date?

    private static let portrait: CGFloat = 72

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            stage(at: elapsed(now: timeline.date))
        }
        .onAppear {
            if animated, started == nil {
                started = Date()
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Goal. \(name)")
    }

    private func elapsed(now: Date) -> TimeInterval {
        guard animated else { return settled }
        guard let started else { return 0 }
        return now.timeIntervalSince(started)
    }

    /// Name and face fully up, before the fade. Reduce motion lands here.
    private var settled: TimeInterval {
        let timing = GoalCelebrationTiming.self
        return timing.seconds(
            timing.ballMilliseconds + timing.wordDelay + timing.wordSpring + timing.cardFade
        )
    }

    private func stage(at elapsed: TimeInterval) -> some View {
        let timing = GoalCelebrationTiming.self
        let wordStart = timing.seconds(timing.ballMilliseconds + timing.wordDelay)
        let cardStart = wordStart + timing.seconds(timing.wordSpring)
        let holdEnd = cardStart + timing.seconds(timing.cardFade + timing.hold)
        let fade = timing.seconds(timing.fadeOut)
        let outro = elapsed < holdEnd ? 1 : max(0, 1 - (elapsed - holdEnd) / fade)
        let wordScale = elapsed < wordStart ? 0 : GoalPop.scale(seconds: elapsed - wordStart)
        let card = elapsed < cardStart ? 0 : min(1, (elapsed - cardStart) / timing.seconds(timing.cardFade))

        return VStack(spacing: theme.space.sm) {
            word
                .scaleEffect(wordScale)
                .opacity(elapsed < wordStart ? 0 : outro)
            cardView
                .opacity(card * outro)
        }
        .padding(.horizontal, theme.space.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var word: some View {
        Image("icon_goalText")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(maxWidth: 280)
            .accessibilityHidden(true)
    }

    private var cardView: some View {
        HStack(spacing: theme.space.sm) {
            PlayerFaceView(face: face, position: position, clubID: clubID)
                .scaleEffect(Self.portrait / 128)
                .frame(width: Self.portrait, height: Self.portrait)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(name)
                .font(theme.type.playerName)
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
            ClubCrest(clubID: clubID, scale: .mark)
                .padding(.trailing, theme.space.xs)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 0, x: 3, y: 3)
    }
}
