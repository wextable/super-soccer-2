import AVFoundation
import ComposableArchitecture

/// Plays the short level-up blip in the app bundle. Tests stay silent.
struct LevelUpSound: Sendable {
    var prepare: @Sendable () async -> Void
    var play: @Sendable () async -> Void
}

extension LevelUpSound: DependencyKey {
    static let liveValue = LevelUpSound(
        prepare: {
            await LevelUpPlayer.shared.prepare()
        },
        play: {
            await LevelUpPlayer.shared.play()
        }
    )

    static let testValue = LevelUpSound(prepare: {}, play: {})

    static let previewValue = LevelUpSound(prepare: {}, play: {})
}

extension DependencyValues {
    var levelUpSound: LevelUpSound {
        get { self[LevelUpSound.self] }
        set { self[LevelUpSound.self] = newValue }
    }
}

/// Holds the player so a short clip is not released the moment it starts.
/// The session and the clip are prepared when the level-up screen appears, so play starts at once.
@MainActor
final class LevelUpPlayer {
    static let shared = LevelUpPlayer()

    private var player: AVAudioPlayer?

    func prepare() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        if player == nil {
            guard let url = Bundle.main.url(forResource: "LevelUp", withExtension: "wav"),
                  let loaded = try? AVAudioPlayer(contentsOf: url)
            else { return }
            player = loaded
        }
        if player?.isPlaying == false {
            player?.prepareToPlay()
        }
    }

    func play() {
        if player == nil {
            prepare()
        }
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }
}
