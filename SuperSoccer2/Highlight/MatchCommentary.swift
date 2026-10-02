import Foundation

/// One voice for a match. Case order is the pick order: the match seed selects it.
enum Commentator: Equatable, Sendable, CaseIterable {
    case pemberton
    case cobb
    case mulch

    var name: String {
        switch self {
        case .pemberton: "Alistair Pemberton"
        case .cobb: "Randy Cobb"
        case .mulch: "Terry Mulch"
        }
    }

    static func forMatch(seed: UInt64) -> Commentator {
        let voices = Self.allCases
        return voices[Int(seed % UInt64(voices.count))]
    }
}

/// The lines for one highlight. The same match seed and shot always build the same lines.
struct MatchCommentary: Equatable, Sendable {
    var commentator: Commentator
    /// A surname, one short phrase, or nothing.
    var lead: String
    /// One ornate or silly line, or nothing. A short chance never has one.
    var aside: String
    /// The finish. Always one sentence.
    var result: String

    var caption: String {
        let parts: [String]
        switch commentator {
        case .mulch:
            parts = [lead, result, aside]
        case .pemberton, .cobb:
            parts = [lead, aside, result]
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func make(shot: Shot, matchSeed: UInt64) -> MatchCommentary {
        let commentator = Commentator.forMatch(seed: matchSeed)
        let script = HighlightScript.make(shot: shot, matchSeed: matchSeed)
        let names = SpokenNames(shot: shot)
        let long = script.beats.count >= 3
        var rng = SeededGenerator(seed: commentarySeed(matchSeed: matchSeed, shot: shot))
        let lead = leadLine(
            commentator: commentator,
            names: names,
            template: script.template,
            long: long,
            using: &rng
        )
        let aside = asideLine(
            commentator: commentator,
            shooter: names.shooter,
            long: long,
            using: &rng
        )
        let result = resultLine(
            commentator: commentator,
            shot: shot,
            finish: script.finish,
            names: names,
            shooterAlreadyNamed: lead.namesShooter
        )
        return MatchCommentary(
            commentator: commentator,
            lead: lead.text,
            aside: aside,
            result: result
        )
    }
}

private struct SpokenLead {
    var text: String
    var namesShooter: Bool
}

/// Surnames, unless two players in the chance share one.
private struct SpokenNames {
    var shooter: String
    var passer: String?
    var keeper: String

    init(shot: Shot) {
        var players = [shot.shooter, shot.keeper]
        if let passer = shot.passer {
            players.append(passer)
        }
        let shared = Dictionary(grouping: players, by: \.lastName).mapValues(\.count)
        func speak(_ player: Player) -> String {
            let surname = player.lastName.isEmpty ? player.firstName : player.lastName
            guard shared[player.lastName, default: 0] > 1, !player.firstName.isEmpty else {
                return surname
            }
            return "\(player.firstName) \(surname)"
        }
        shooter = speak(shot.shooter)
        passer = shot.passer.map(speak)
        keeper = speak(shot.keeper)
    }
}

extension MatchCommentary {
    private static func leadLine(
        commentator: Commentator,
        names: SpokenNames,
        template: HighlightTemplate,
        long: Bool,
        using rng: inout SeededGenerator
    ) -> SpokenLead {
        let roll = Int(rng.next() % UInt64(long ? 5 : 2))
        if long, roll == 4 {
            return SpokenLead(text: phrase(commentator, names: names, template: template), namesShooter: true)
        }
        let saysSurname = long ? roll == 2 || roll == 3 : roll == 1
        if saysSurname {
            return SpokenLead(text: surname(commentator, names.shooter), namesShooter: true)
        }
        return SpokenLead(text: "", namesShooter: false)
    }

    private static func surname(_ commentator: Commentator, _ shooter: String) -> String {
        switch commentator {
        case .pemberton, .mulch:
            "\(shooter)."
        case .cobb:
            "\(shooter)!"
        }
    }

    private static func phrase(
        _ commentator: Commentator,
        names: SpokenNames,
        template: HighlightTemplate
    ) -> String {
        let shooter = names.shooter
        let pass = names.passer.map { "\($0) to \(shooter)" }
        switch commentator {
        case .pemberton, .mulch:
            switch template {
            case .wing:
                return "\(shooter), in oceans of space."
            case .counter:
                return "\(shooter), away on the break."
            case .cutback:
                return "\(shooter), from the byline."
            case .oneTwo, .throughTheMiddle:
                if let pass {
                    return "\(pass)."
                }
                return "\(shooter), through the middle."
            case .penalty:
                return surname(commentator, shooter)
            }
        case .cobb:
            switch template {
            case .wing:
                return "\(shooter)! He's got room!"
            case .counter:
                return "\(shooter)! He's gone!"
            case .cutback:
                return "\(shooter)! On the line!"
            case .oneTwo, .throughTheMiddle:
                if let pass {
                    return "\(pass)!"
                }
                return "\(shooter)! He's got room!"
            case .penalty:
                return surname(commentator, shooter)
            }
        }
    }

    private static func asideLine(
        commentator: Commentator,
        shooter: String,
        long: Bool,
        using rng: inout SeededGenerator
    ) -> String {
        guard long, commentator != .cobb, rng.next() % 4 == 0 else { return "" }
        let pick = Int(rng.next() % 3)
        switch commentator {
        case .pemberton:
            if pick == 0 {
                return "A look of mystification on the angular face of \(shooter)."
            }
            return "A faintly bewildered hush follows \(shooter)."
        case .mulch:
            switch pick {
            case 0:
                return "Like a fridge winning a race against a lawnmower."
            case 1:
                return "I had a thought and then it left."
            default:
                return "Which is a swan, or a parking meter."
            }
        case .cobb:
            return ""
        }
    }

    private static func resultLine(
        commentator: Commentator,
        shot: Shot,
        finish: ShotFinish,
        names: SpokenNames,
        shooterAlreadyNamed: Bool
    ) -> String {
        let shooter = names.shooter
        let keeper = names.keeper
        let penalty = shot.type == .penalty
        switch commentator {
        case .pemberton:
            switch shot.result {
            case .goal:
                return penalty
                    ? "And \(shooter), rather beautifully, is in from the spot."
                    : "And \(shooter), rather beautifully, is in."
            case .save:
                return penalty
                    ? "\(keeper) saves the penalty, which will do."
                    : "\(keeper) saves, which will do."
            case .miss:
                if penalty { return "\(shooter) misses from the spot." }
                return finish == .over ? "\(shooter) puts it over." : "\(shooter) puts it wide."
            }
        case .cobb:
            switch shot.result {
            case .goal:
                return penalty ? "\(shooter) buries the penalty!" : "\(shooter) buries it!"
            case .save:
                return penalty ? "\(keeper) stops the penalty." : "\(keeper) stops it."
            case .miss:
                if penalty {
                    return finish == .over ? "\(shooter) skies the penalty!" : "\(shooter) shanks the penalty!"
                }
                if finish == .over {
                    return shooterAlreadyNamed ? "And he skies it." : "\(shooter) skies it!"
                }
                return shooterAlreadyNamed ? "And he shanks it." : "\(shooter) shanks it!"
            }
        case .mulch:
            switch shot.result {
            case .goal:
                return penalty ? "\(shooter) scores the penalty." : "\(shooter) scores."
            case .save:
                return penalty ? "\(keeper) saves the penalty." : "\(keeper) saves."
            case .miss:
                return penalty ? "\(shooter) misses the penalty." : "\(shooter) misses."
            }
        }
    }

    private static func commentarySeed(matchSeed: UInt64, shot: Shot) -> UInt64 {
        var mixed = matchSeed &+ 0xC0FF_EE00_C0FF_EE01
        mixed ^= UInt64(bitPattern: Int64(shot.id)) &* 0x9E37_79B9_7F4A_7C15
        mixed ^= UInt64(shot.minute) &* 0xBF58_476D_1CE4_E5B9
        mixed ^= shot.isHome ? 0xA5A5_A5A5_A5A5_A5A5 : 0x5A5A_5A5A_5A5A_5A5A
        switch shot.result {
        case .goal:
            mixed ^= 0x1111_1111_1111_1111
        case .save:
            mixed ^= 0x2222_2222_2222_2222
        case .miss:
            mixed ^= 0x3333_3333_3333_3333
        }
        if shot.type == .penalty {
            mixed ^= 0x4444_4444_4444_4444
        }
        if shot.passer != nil {
            mixed ^= 0x5555_5555_5555_5555
        }
        return mixed == 0 ? 1 : mixed
    }
}
