import Foundation

/// Why a player is leveling up. The lines are the old game's, including the ones that are not polite.
enum LevelUpCopy {
    static let lines = [
        "has been working hard!",
        "was practicing late at night all week long.",
        "is really dedicated to his craft.",
        "is a gym rat.",
        "keeps getting better!",
        "has been honing his skills.",
        "doesn't fuck around.",
        "is turning heads at practice.",
        "just doesn't ever give up!",
        "looks like he's been working out.",
        "is always trying to improve.",
        "is turning into a stud.",
        "has caught our eye this week.",
        "really wants to be a good player.",
        "must have had sex this week.",
        "totally got a blowjob in the parking lot.",
        "started micro-dosing.",
        "went on a zen meditation retreat.",
        "FINALLY got those genital warts removed!",
        "might have some real potential.",
    ]

    /// Same offer, same line. The week can rebuild this screen without swapping the sentence.
    static func line(for offerID: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in offerID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return lines[Int(hash % UInt64(lines.count))]
    }

    static func sentence(name: String, offerID: String) -> String {
        "\(name) \(line(for: offerID))"
    }
}
