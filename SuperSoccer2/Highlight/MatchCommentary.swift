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
            names: names,
            template: script.template,
            long: long,
            using: &rng
        )
        let result = resultLine(
            commentator: commentator,
            template: script.template,
            finish: script.finish,
            names: names,
            using: &rng
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
            return SpokenLead(text: phrase(commentator, names: names, template: template, using: &rng))
        }
        let saysSurname = long ? roll == 2 || roll == 3 : roll == 1
        if saysSurname {
            return SpokenLead(text: surname(commentator, names.shooter))
        }
        return SpokenLead(text: "")
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
        template: HighlightTemplate,
        using rng: inout SeededGenerator
    ) -> String {
        guard template != .penalty else { return surname(commentator, names.shooter) }
        var pool = CommentaryPhrases.leads(voice: commentator, template: template)
        if names.passer == nil {
            pool = pool.filter { !$0.contains("{P}") }
        }
        guard !pool.isEmpty else { return surname(commentator, names.shooter) }
        let line = pool[Int(rng.next() % UInt64(pool.count))]
        return CommentaryPhrases.fill(line, shooter: names.shooter, passer: names.passer, keeper: names.keeper)
    }

    private static func asideLine(
        commentator: Commentator,
        names: SpokenNames,
        template: HighlightTemplate,
        long: Bool,
        using rng: inout SeededGenerator
    ) -> String {
        guard long, commentator != .cobb, template != .penalty, rng.next() % 4 == 0 else { return "" }
        let pool = CommentaryPhrases.asides(voice: commentator, template: template)
        guard !pool.isEmpty else { return "" }
        let line = pool[Int(rng.next() % UInt64(pool.count))]
        return CommentaryPhrases.fill(line, shooter: names.shooter, passer: names.passer, keeper: names.keeper)
    }

    private static func resultLine(
        commentator: Commentator,
        template: HighlightTemplate,
        finish: ShotFinish,
        names: SpokenNames,
        using rng: inout SeededGenerator
    ) -> String {
        let passed = template != .penalty && names.passer != nil
        let pool = CommentaryPhrases.results(
            voice: commentator,
            template: template,
            passed: passed,
            finish: finish
        )
        let line = pool[Int(rng.next() % UInt64(pool.count))]
        return CommentaryPhrases.fill(line, shooter: names.shooter, passer: names.passer, keeper: names.keeper)
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
