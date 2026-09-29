import AVFoundation
import ComposableArchitecture

/// Plays the short level-up blip in the app bundle. Tests stay silent.
struct LevelUpSound: Sendable {
    var play: @Sendable () async -> Void
}

extension LevelUpSound: DependencyKey {
    static let liveValue = LevelUpSound(
        play: {
            await LevelUpPlayer.shared.play()
        }
    )

    static let testValue = LevelUpSound(play: {})

    static let previewValue = LevelUpSound(play: {})
}

extension DependencyValues {
    var levelUpSound: LevelUpSound {
        get { self[LevelUpSound.self] }
        set { self[LevelUpSound.self] = newValue }
    }
}

/// Holds the player so a short clip is not released the moment it starts.
@MainActor
final class LevelUpPlayer {
    static let shared = LevelUpPlayer()

    private var player: AVAudioPlayer?

    func play() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        guard let url = Bundle.main.url(forResource: "LevelUp", withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return }
        self.player = player
        player.play()
    }
}
