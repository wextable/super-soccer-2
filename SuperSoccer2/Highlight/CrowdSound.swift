import AVFoundation
import ComposableArchitecture

/// What the crowd is doing. The bed loops. A goal roars. A save or a miss groans.
enum CrowdMoment: String, Sendable {
    case ambient
    case goal
    case save
    case miss

    init(_ result: ShotResult) {
        switch result {
        case .goal: self = .goal
        case .save: self = .save
        case .miss: self = .miss
        }
    }
}

/// The match crowd. Tests stay silent.
struct CrowdSound: Sendable {
    var prepare: @Sendable () async -> Void
    var play: @Sendable (CrowdMoment) async -> Void
    var stop: @Sendable () async -> Void
}

extension CrowdSound: DependencyKey {
    static let liveValue = CrowdSound(
        prepare: {
            await CrowdPlayer.shared.prepare()
        },
        play: { moment in
            await CrowdPlayer.shared.play(moment)
        },
        stop: {
            await CrowdPlayer.shared.stop()
        }
    )

    static let testValue = CrowdSound(
        prepare: {},
        play: { _ in },
        stop: {}
    )

    static let previewValue = CrowdSound(
        prepare: {},
        play: { _ in },
        stop: {}
    )
}

extension DependencyValues {
    var crowdSound: CrowdSound {
        get { self[CrowdSound.self] }
        set { self[CrowdSound.self] = newValue }
    }
}

/// The three clips stay loaded so the first chance does not hitch.
/// The session matches the level-up blip. Volumes match the old crowd.
@MainActor
final class CrowdPlayer {
    static let shared = CrowdPlayer()

    private static let ambientLevel: Float = 0.1
    private static let excitedLevel: Float = 0.4
    private static let sadLevel: Float = 0.25

    private var ambient: AVAudioPlayer?
    private var excited: AVAudioPlayer?
    private var sad: AVAudioPlayer?

    func prepare() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        if ambient == nil {
            ambient = load("crowd_ambient", volume: Self.ambientLevel, loops: true)
        }
        if excited == nil {
            excited = load("crowd_excited", volume: Self.excitedLevel, loops: false)
        }
        if sad == nil {
            sad = load("crowd_sad", volume: Self.sadLevel, loops: false)
        }
        for player in [ambient, excited, sad] {
            if player?.isPlaying == false {
                player?.prepareToPlay()
            }
        }
    }

    func play(_ moment: CrowdMoment) {
        if ambient == nil || excited == nil || sad == nil {
            prepare()
        }
        switch moment {
        case .ambient:
            guard let ambient, !ambient.isPlaying else { return }
            ambient.currentTime = 0
            ambient.play()
        case .goal:
            sad?.stop()
            restart(excited)
        case .save, .miss:
            excited?.stop()
            restart(sad)
        }
    }

    func stop() {
        ambient?.stop()
        excited?.stop()
        sad?.stop()
    }

    private func restart(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private func load(_ name: String, volume: Float, loops: Bool) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }
        player.volume = volume
        player.numberOfLoops = loops ? -1 : 0
        return player
    }
}
