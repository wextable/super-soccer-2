import Foundation

/// One line for one move and one finish.
/// `{S}` is the shooter, `{P}` the passer, and `{K}` the keeper.
enum CommentaryPhrases {
    static func results(
        voice: Commentator,
        template: HighlightTemplate,
        passed: Bool,
        finish: ShotFinish
    ) -> [String] {
        let key = resultKey(voice: voice, template: template, passed: passed, finish: finish)
        guard let lines = resultBanks[key] else {
            preconditionFailure("No commentary for \(key)")
        }
        return lines
    }

    static func leads(voice: Commentator, template: HighlightTemplate) -> [String] {
        let key = "\(voiceTag(voice))|\(templateTag(template))"
        guard let lines = leadBanks[key] else {
            preconditionFailure("No commentary lead for \(key)")
        }
        return lines
    }

    static func asides(voice: Commentator, template: HighlightTemplate) -> [String] {
        let key = "\(voiceTag(voice))|\(templateTag(template))"
        return asideBanks[key] ?? []
    }

    static func fill(_ line: String, shooter: String, passer: String?, keeper: String) -> String {
        var text = line.replacingOccurrences(of: "{S}", with: shooter)
        text = text.replacingOccurrences(of: "{K}", with: keeper)
        guard text.contains("{P}") else { return text }
        guard let passer else {
            preconditionFailure("Commentary names a passer this chance does not have")
        }
        return text.replacingOccurrences(of: "{P}", with: passer)
    }

    static func lineCount(voice: Commentator) -> Int {
        let prefix = voiceTag(voice) + "|"
        func total(_ banks: [String: [String]]) -> Int {
            banks.reduce(0) { count, entry in
                entry.key.hasPrefix(prefix) ? count + entry.value.count : count
            }
        }
        return total(resultBanks) + total(leadBanks) + total(asideBanks)
    }

    private static func resultKey(
        voice: Commentator,
        template: HighlightTemplate,
        passed: Bool,
        finish: ShotFinish
    ) -> String {
        let approach = template == .penalty || !passed ? "solo" : "pass"
        return "\(voiceTag(voice))|\(templateTag(template))|\(approach)|\(finishTag(finish))"
    }

    private static func voiceTag(_ voice: Commentator) -> String {
        switch voice {
        case .pemberton: "pemberton"
        case .cobb: "cobb"
        case .mulch: "mulch"
        }
    }

    private static func templateTag(_ template: HighlightTemplate) -> String {
        switch template {
        case .wing: "wing"
        case .throughTheMiddle: "through"
        case .counter: "counter"
        case .oneTwo: "oneTwo"
        case .cutback: "cutback"
        case .penalty: "penalty"
        }
    }

    private static func finishTag(_ finish: ShotFinish) -> String {
        switch finish {
        case .net: "goal"
        case .keeper: "save"
        case .wide: "wide"
        case .over: "over"
        }
    }

    private static let resultBanks: [String: [String]] = [
        "pemberton|wing|pass|goal": [
            "And {S}, rather beautifully, meets the cross.",
            "{P} swings the cross, and {S} is in.",
            "From the flank, {S} finishes.",
            "The touchline ball, and {S} has scored.",
            "{S} converts the cross from {P}.",
        ],
        "pemberton|wing|pass|save": [
            "{K} saves the cross, which will do.",
            "The cross from {P} is held by {K}.",
            "{K} gathers the ball from the wing.",
            "The flank ball, and {K} saves.",
            "{K} keeps the cross out.",
        ],
        "pemberton|wing|pass|wide": [
            "{S} puts the cross wide.",
            "{P} crosses, and {S} is past the post.",
            "The flank ball, and {S} misses wide.",
            "{S} meets the cross and puts it wide.",
            "From the wing, {S} is wide of the post.",
        ],
        "pemberton|wing|pass|over": [
            "{S} puts the cross over.",
            "{P} crosses, and {S} clears the bar.",
            "The flank ball goes over off {S}.",
            "{S} meets the cross and sends it over.",
            "From the wing, {S} is over the bar.",
        ],
        "pemberton|wing|solo|goal": [
            "And {S}, rather beautifully, cuts in off the wing.",
            "{S} comes off the flank, and that is in.",
            "A touchline run, and {S} finishes.",
            "{S} drives the wing, and the shot is in.",
            "From the wing, {S} scores.",
        ],
        "pemberton|wing|solo|save": [
            "{K} saves the wing shot, which will do.",
            "{K} gathers after the flank run.",
            "From the touchline, {K} saves.",
            "{K} holds the effort off the wing.",
            "{S} cuts in from the wing, and {K} saves.",
        ],
        "pemberton|wing|solo|wide": [
            "{S} puts the wing shot wide.",
            "Off the flank, {S} misses the post.",
            "{S} cuts in from the wing and drags it wide.",
            "The touchline run ends wide from {S}.",
            "{S} is wide from the wing.",
        ],
        "pemberton|wing|solo|over": [
            "{S} puts the wing shot over.",
            "Off the flank, {S} clears the bar.",
            "{S} cuts in from the wing and lifts it over.",
            "The touchline run ends over from {S}.",
            "{S} is over from the wing.",
        ],
        "pemberton|through|pass|goal": [
            "And {S}, rather beautifully, is in through the middle.",
            "{P} slides it centrally, and {S} scores.",
            "Through the channel, {S} finishes.",
            "{S} meets the ball in the middle.",
            "A central pass from {P}, and {S} is in.",
        ],
        "pemberton|through|pass|save": [
            "{K} saves the central shot, which will do.",
            "The ball through the middle from {P} is held by {K}.",
            "{K} gathers in the channel.",
            "Through the middle, and {K} saves.",
            "{K} keeps out the central effort.",
        ],
        "pemberton|through|pass|wide": [
            "{S} puts the central pass wide.",
            "Through the middle, {S} misses the post.",
            "{P} finds the channel, and {S} puts it wide.",
            "{S} is wide from the channel.",
            "The central ball, and {S} drags it wide.",
        ],
        "pemberton|through|pass|over": [
            "{S} puts the central pass over.",
            "Through the middle, {S} clears the bar.",
            "{P} finds the channel, and {S} sends it over.",
            "{S} is over from the channel.",
            "The central ball, and {S} lifts it over.",
        ],
        "pemberton|through|solo|goal": [
            "And {S}, rather beautifully, goes through the middle.",
            "{S} carries the channel, and that is in.",
            "Straight through the middle, {S} finishes.",
            "{S} drives centrally, and the shot is in.",
            "The middle opens, and {S} scores.",
        ],
        "pemberton|through|solo|save": [
            "{K} saves the run through the middle, which will do.",
            "{K} gathers the channel shot.",
            "{S} comes centrally, and {K} saves.",
            "The middle, and {K} holds it.",
            "{K} keeps out the shot from the channel.",
        ],
        "pemberton|through|solo|wide": [
            "{S} puts the middle shot wide.",
            "Through the channel, {S} misses the post.",
            "{S} goes centrally and drags it wide.",
            "{S} is wide from the middle.",
            "The central run ends wide off {S}.",
        ],
        "pemberton|through|solo|over": [
            "{S} puts the middle shot over.",
            "Through the channel, {S} clears the bar.",
            "{S} goes centrally and lifts it over.",
            "{S} is over from the middle.",
            "The central run ends over off {S}.",
        ],
        "pemberton|counter|pass|goal": [
            "And {S}, rather beautifully, finishes the break.",
            "{P} releases {S}, and the counter is in.",
            "On the counter, {S} scores.",
            "{S} runs the break, and that is in.",
            "A counter from {P}, and {S} has it.",
        ],
        "pemberton|counter|pass|save": [
            "{K} saves on the break, which will do.",
            "The counter from {P} is held by {K}.",
            "{K} gathers the break.",
            "{S} runs the counter, and {K} saves.",
            "{K} keeps out the counter.",
        ],
        "pemberton|counter|pass|wide": [
            "{S} puts the break wide.",
            "On the counter, {S} misses the post.",
            "{P} sends the break, and {S} drags it wide.",
            "{S} is wide at the end of the break.",
            "The counter, and {S} puts it wide.",
        ],
        "pemberton|counter|pass|over": [
            "{S} puts the break over.",
            "On the counter, {S} clears the bar.",
            "{P} sends the break, and {S} lifts it over.",
            "{S} is over at the end of the break.",
            "The counter, and {S} puts it over.",
        ],
        "pemberton|counter|solo|goal": [
            "And {S}, rather beautifully, finishes on the break.",
            "{S} is away on the counter, and in.",
            "The break, and {S} scores.",
            "{S} carries the counter, and the shot is in.",
            "Clean away on the break, {S} finishes.",
        ],
        "pemberton|counter|solo|save": [
            "{K} saves the break, which will do.",
            "{K} gathers on the counter.",
            "{S} is away on the break, and {K} saves.",
            "The counter, and {K} holds it.",
            "{K} keeps {S} out on the break.",
        ],
        "pemberton|counter|solo|wide": [
            "{S} puts the counter wide.",
            "On the break, {S} misses the post.",
            "{S} drags the break wide.",
            "{S} is wide on the counter.",
            "The break ends wide off {S}.",
        ],
        "pemberton|counter|solo|over": [
            "{S} puts the counter over.",
            "On the break, {S} clears the bar.",
            "{S} lifts the break over.",
            "{S} is over on the counter.",
            "The break ends over off {S}.",
        ],
        "pemberton|oneTwo|pass|goal": [
            "And {S}, rather beautifully, takes the one-two.",
            "{P} plays the one-two, and {S} is in.",
            "The one-two, and {S} finishes.",
            "{S} plays it on, and the one-two is in.",
            "A one-two with {P}, and {S} scores.",
        ],
        "pemberton|oneTwo|pass|save": [
            "{K} saves the one-two, which will do.",
            "The one-two from {P} is held by {K}.",
            "{K} gathers after the one-two.",
            "{S} takes the one-two, and {K} saves.",
            "{K} keeps out the one-two.",
        ],
        "pemberton|oneTwo|pass|wide": [
            "{S} puts the one-two wide.",
            "The one-two from {P}, and {S} misses the post.",
            "{S} takes the one-two and drags it wide.",
            "{S} is wide after the one-two.",
            "{P} sets the one-two, and {S} puts it wide.",
        ],
        "pemberton|oneTwo|pass|over": [
            "{S} puts the one-two over.",
            "The one-two from {P}, and {S} clears the bar.",
            "{S} lifts the one-two over.",
            "{S} is over after the one-two.",
            "{P} sets the one-two, and {S} sends it over.",
        ],
        "pemberton|oneTwo|solo|goal": [
            "And {S}, rather beautifully, finishes the one-two.",
            "The one-two comes back, and {S} is in.",
            "{S} completes the one-two.",
            "After the one-two, {S} scores.",
            "The one-two, and {S} has it.",
        ],
        "pemberton|oneTwo|solo|save": [
            "{K} saves that one-two, which will do.",
            "{K} gathers the one-two.",
            "{S} finishes the one-two, and {K} saves.",
            "The one-two, and {K} holds it.",
            "{K} keeps the one-two out.",
        ],
        "pemberton|oneTwo|solo|wide": [
            "{S} puts that one-two wide.",
            "After the one-two, {S} misses the post.",
            "{S} drags the one-two wide.",
            "{S} is wide from the one-two.",
            "The one-two ends wide off {S}.",
        ],
        "pemberton|oneTwo|solo|over": [
            "{S} puts that one-two over.",
            "After the one-two, {S} clears the bar.",
            "{S} lifts that one-two over.",
            "{S} is over from the one-two.",
            "The one-two ends over off {S}.",
        ],
        "pemberton|cutback|pass|goal": [
            "And {S}, rather beautifully, takes the cutback.",
            "{P} pulls it from the byline, and {S} is in.",
            "The cutback, and {S} finishes.",
            "{S} meets the cutback from {P}.",
            "From the byline, {S} scores.",
        ],
        "pemberton|cutback|pass|save": [
            "{K} saves the cutback, which will do.",
            "The byline ball from {P} is held by {K}.",
            "{K} gathers the cutback.",
            "{S} meets the cutback, and {K} saves.",
            "{K} keeps the cutback out.",
        ],
        "pemberton|cutback|pass|wide": [
            "{S} puts the cutback wide.",
            "From the byline, {S} misses the post.",
            "{P} plays the cutback, and {S} is wide.",
            "{S} meets the cutback and puts it wide.",
            "The byline ball, and {S} drags it wide.",
        ],
        "pemberton|cutback|pass|over": [
            "{S} puts the cutback over.",
            "From the byline, {S} clears the bar.",
            "{P} plays the cutback, and {S} is over.",
            "{S} meets the cutback and sends it over.",
            "The byline ball, and {S} lifts it over.",
        ],
        "pemberton|cutback|solo|goal": [
            "And {S}, rather beautifully, scores the cutback.",
            "{S} reaches the byline, and that is in.",
            "The cutback is finished by {S}.",
            "{S} pulls the cutback in from the byline.",
            "Off the byline, {S} finishes.",
        ],
        "pemberton|cutback|solo|save": [
            "{K} saves the byline shot, which will do.",
            "{K} gathers off the byline.",
            "{S} plays the cutback, and {K} saves.",
            "The byline, and {K} holds it.",
            "{K} keeps the byline effort out.",
        ],
        "pemberton|cutback|solo|wide": [
            "{S} puts the byline shot wide.",
            "Off the cutback, {S} misses the post.",
            "{S} drags the cutback wide.",
            "{S} is wide from the byline.",
            "The cutback ends wide off {S}.",
        ],
        "pemberton|cutback|solo|over": [
            "{S} puts the byline shot over.",
            "Off the cutback, {S} clears the bar.",
            "{S} lifts the cutback over.",
            "{S} is over from the byline.",
            "The cutback ends over off {S}.",
        ],
        "pemberton|penalty|solo|goal": [
            "And {S}, rather beautifully, is in from the spot.",
            "{S} converts the penalty.",
            "From the spot, {S} is in.",
            "A composed penalty, and {S} has it.",
            "{S} places the penalty in.",
        ],
        "pemberton|penalty|solo|save": [
            "{K} saves the penalty, which will do.",
            "{K} keeps out the spot-kick.",
            "{K} gathers the penalty.",
            "From the spot, {K} saves.",
            "{K} holds the penalty.",
        ],
        "pemberton|penalty|solo|wide": [
            "{S} puts the penalty wide.",
            "From the spot, {S} misses the post.",
            "{S} sends the penalty past the post.",
            "The spot-kick, and {S} is wide.",
            "{S} places the penalty wide.",
        ],
        "pemberton|penalty|solo|over": [
            "{S} puts the penalty over.",
            "From the spot, {S} clears the bar.",
            "{S} lifts the penalty over.",
            "The spot-kick goes over off {S}.",
            "{S} is over from the spot.",
        ],
        "cobb|wing|pass|goal": [
            "{S} buries the cross!",
            "{S} slots {P}'s cross!",
            "{S} finishes the cross!",
            "{P} crossed, {S} scores!",
            "{S} slams the cross!",
        ],
        "cobb|wing|pass|save": [
            "{K} stops the cross.",
            "{K} punches the cross!",
            "{P} crossed, {K} saves!",
            "{K} holds the cross.",
            "{K} denies the cross!",
        ],
        "cobb|wing|pass|wide": [
            "{S} shanks the cross!",
            "{S} drags the cross!",
            "{S} misses the cross!",
            "{P} crossed, {S} wide!",
            "{S} pulls the cross!",
        ],
        "cobb|wing|pass|over": [
            "{S} skies the cross!",
            "{S} floats the cross!",
            "{S} spoons the cross!",
            "{P} crossed, {S} over!",
            "{S} lofts the cross!",
        ],
        "cobb|wing|solo|goal": [
            "{S} buries the wing!",
            "{S} slots the flank!",
            "{S} finishes the flank!",
            "{S} rips the wing!",
            "{S} slams the touchline!",
        ],
        "cobb|wing|solo|save": [
            "{K} stops the wing.",
            "{K} punches the flank!",
            "{K} holds the wing.",
            "{K} denies the flank!",
            "{K} saves the touchline.",
        ],
        "cobb|wing|solo|wide": [
            "{S} shanks the wing!",
            "{S} drags the flank!",
            "{S} misses the wing!",
            "{S} yanks the flank!",
            "{S} blows the touchline!",
        ],
        "cobb|wing|solo|over": [
            "{S} skies the wing!",
            "{S} floats the flank!",
            "{S} spoons the wing!",
            "{S} lofts the flank!",
            "{S} hoists the touchline!",
        ],
        "cobb|through|pass|goal": [
            "{S} buries it central!",
            "{S} slots the channel!",
            "{S} finishes central!",
            "{S} scores the channel!",
            "{P} central, {S} scores!",
        ],
        "cobb|through|pass|save": [
            "{K} stops the channel.",
            "{K} punches it central!",
            "{P} central, {K} saves!",
            "{K} holds the middle.",
            "{K} denies the channel!",
        ],
        "cobb|through|pass|wide": [
            "{S} shanks the channel!",
            "{S} drags it central!",
            "{S} misses the middle!",
            "{P} central, {S} wide!",
            "{S} pulls the channel!",
        ],
        "cobb|through|pass|over": [
            "{S} skies the channel!",
            "{S} floats it central!",
            "{S} spoons the middle!",
            "{P} central, {S} over!",
            "{S} lofts the channel!",
        ],
        "cobb|through|solo|goal": [
            "{S} buries the channel!",
            "{S} slots the middle!",
            "{S} finishes the middle!",
            "{S} scores central!",
            "{S} slams the channel!",
        ],
        "cobb|through|solo|save": [
            "{K} stops the middle.",
            "{K} punches the channel!",
            "{K} holds the channel.",
            "{K} denies central!",
            "{K} saves the middle.",
        ],
        "cobb|through|solo|wide": [
            "{S} shanks the middle!",
            "{S} drags the channel!",
            "{S} misses central!",
            "{S} yanks the middle!",
            "{S} blows the channel!",
        ],
        "cobb|through|solo|over": [
            "{S} skies the middle!",
            "{S} floats the channel!",
            "{S} spoons central!",
            "{S} lofts the middle!",
            "{S} hoists the channel!",
        ],
        "cobb|counter|pass|goal": [
            "{S} buries the break!",
            "{S} slots the counter!",
            "{S} finishes the break!",
            "{S} scores the counter!",
            "{S} slams the break!",
        ],
        "cobb|counter|pass|save": [
            "{K} stops the break.",
            "{K} punches the counter!",
            "{P} break, {K} saves!",
            "{K} holds the break.",
            "{K} denies the counter!",
        ],
        "cobb|counter|pass|wide": [
            "{S} shanks the break!",
            "{S} drags the counter!",
            "{S} misses the break!",
            "{P} break, {S} wide!",
            "{S} pulls the counter!",
        ],
        "cobb|counter|pass|over": [
            "{S} skies the break!",
            "{S} floats the counter!",
            "{S} spoons the break!",
            "{P} break, {S} over!",
            "{S} lofts the counter!",
        ],
        "cobb|counter|solo|goal": [
            "{S} buries the counter!",
            "{S} slots the break!",
            "{S} finishes the counter!",
            "{S} scores the break!",
            "{S} slams the counter!",
        ],
        "cobb|counter|solo|save": [
            "{K} stops the counter.",
            "{K} punches the break!",
            "{K} holds the counter.",
            "{K} denies the break!",
            "{K} saves the break.",
        ],
        "cobb|counter|solo|wide": [
            "{S} shanks the counter!",
            "{S} drags the break!",
            "{S} misses the counter!",
            "{S} yanks the break!",
            "{S} blows the counter!",
        ],
        "cobb|counter|solo|over": [
            "{S} skies the counter!",
            "{S} floats the break!",
            "{S} spoons the counter!",
            "{S} lofts the break!",
            "{S} hoists the counter!",
        ],
        "cobb|oneTwo|pass|goal": [
            "{S} buries the one-two!",
            "{S} slots the one-two!",
            "{S} finishes the one-two!",
            "{S} scores the one-two!",
            "{S} slams the one-two!",
        ],
        "cobb|oneTwo|pass|save": [
            "{K} stops the one-two.",
            "{K} punches the one-two!",
            "{P} one-two, {K} saves!",
            "{K} holds the one-two.",
            "{K} denies the one-two!",
        ],
        "cobb|oneTwo|pass|wide": [
            "{S} shanks the one-two!",
            "{S} drags the one-two!",
            "{S} misses the one-two!",
            "{P} one-two, {S} wide!",
            "{S} pulls the one-two!",
        ],
        "cobb|oneTwo|pass|over": [
            "{S} skies the one-two!",
            "{S} floats the one-two!",
            "{S} spoons the one-two!",
            "{P} one-two, {S} over!",
            "{S} lofts the one-two!",
        ],
        "cobb|oneTwo|solo|goal": [
            "{S} tucks the one-two!",
            "{S} pokes the one-two!",
            "{S} rips the one-two!",
            "{S} nails the one-two!",
            "{S} bangs the one-two!",
        ],
        "cobb|oneTwo|solo|save": [
            "{K} stops that one-two.",
            "{K} grabs the one-two!",
            "{K} holds that one-two.",
            "{K} denies that one-two!",
            "{K} saves that one-two.",
        ],
        "cobb|oneTwo|solo|wide": [
            "{S} shanks that one-two!",
            "{S} drags that one-two!",
            "{S} yanks the one-two!",
            "{S} blows the one-two!",
            "{S} misses that one-two!",
        ],
        "cobb|oneTwo|solo|over": [
            "{S} skies that one-two!",
            "{S} floats that one-two!",
            "{S} spoons that one-two!",
            "{S} lofts that one-two!",
            "{S} hoists the one-two!",
        ],
        "cobb|cutback|pass|goal": [
            "{S} buries the cutback!",
            "{S} slots the byline!",
            "{S} finishes the cutback!",
            "{S} slams the byline!",
            "{S} tucks the cutback!",
        ],
        "cobb|cutback|pass|save": [
            "{K} stops the cutback.",
            "{K} punches the byline!",
            "{P} cutback, {K} saves!",
            "{K} holds the cutback.",
            "{K} denies the byline!",
        ],
        "cobb|cutback|pass|wide": [
            "{S} shanks the cutback!",
            "{S} drags the byline!",
            "{S} misses the cutback!",
            "{P} cutback, {S} wide!",
            "{S} pulls the cutback!",
        ],
        "cobb|cutback|pass|over": [
            "{S} skies the cutback!",
            "{S} floats the byline!",
            "{S} spoons the cutback!",
            "{P} cutback, {S} over!",
            "{S} lofts the byline!",
        ],
        "cobb|cutback|solo|goal": [
            "{S} buries the byline!",
            "{S} slots the cutback!",
            "{S} rips the cutback!",
            "{S} nails the byline!",
            "{S} pokes the byline!",
        ],
        "cobb|cutback|solo|save": [
            "{K} stops the byline.",
            "{K} punches the cutback!",
            "{K} holds the byline.",
            "{K} denies the cutback!",
            "{K} saves the cutback.",
        ],
        "cobb|cutback|solo|wide": [
            "{S} shanks the byline!",
            "{S} drags the cutback!",
            "{S} misses the byline!",
            "{S} yanks the cutback!",
            "{S} blows the byline!",
        ],
        "cobb|cutback|solo|over": [
            "{S} skies the byline!",
            "{S} floats the cutback!",
            "{S} spoons the byline!",
            "{S} lofts the cutback!",
            "{S} hoists the byline!",
        ],
        "cobb|penalty|solo|goal": [
            "{S} buries the penalty!",
            "{S} slams the penalty!",
            "{S} blasts the spot!",
            "{S} rips the penalty!",
            "{S} slots the spot!",
        ],
        "cobb|penalty|solo|save": [
            "{K} stops the penalty.",
            "{K} saves the spot.",
            "{K} holds the penalty.",
            "{K} denies the spot!",
            "{K} gets the penalty.",
        ],
        "cobb|penalty|solo|wide": [
            "{S} shanks the penalty!",
            "{S} drags the spot!",
            "{S} misses the penalty!",
            "{S} pulls the spot!",
            "{S} blows the spot!",
        ],
        "cobb|penalty|solo|over": [
            "{S} skies the penalty!",
            "{S} floats the spot!",
            "{S} spoons the penalty!",
            "{S} lofts the spot!",
            "{S} skies the spot!",
        ],
        "mulch|wing|pass|goal": [
            "{S} scores from the cross.",
            "{P} crosses and {S} scores.",
            "The cross goes in off {S}.",
            "{S} puts the cross in the net.",
            "A flank cross, goal for {S}.",
        ],
        "mulch|wing|pass|save": [
            "{K} saves the cross.",
            "{P} crosses and {K} saves.",
            "The cross is saved by {K}.",
            "{K} keeps the cross.",
            "{S} hits the cross and {K} saves.",
        ],
        "mulch|wing|pass|wide": [
            "{S} misses the cross wide.",
            "{P} crosses and {S} puts it wide.",
            "The cross goes wide off {S}.",
            "{S} hits the cross past the post.",
            "From the wing, {S} misses wide.",
        ],
        "mulch|wing|pass|over": [
            "{S} misses the cross over.",
            "{P} crosses and {S} puts it over.",
            "The cross goes over off {S}.",
            "{S} hits the cross over the bar.",
            "From the wing, {S} misses over.",
        ],
        "mulch|wing|solo|goal": [
            "{S} scores off the wing.",
            "{S} scores from the flank.",
            "The wing run goes in for {S}.",
            "{S} puts the flank shot in.",
            "Off the touchline, {S} scores.",
        ],
        "mulch|wing|solo|save": [
            "{K} saves the wing shot.",
            "{K} saves the flank effort.",
            "The touchline shot is saved by {K}.",
            "{K} keeps the wing shot out.",
            "{S} shoots from the wing and {K} saves.",
        ],
        "mulch|wing|solo|wide": [
            "{S} misses the wing shot wide.",
            "Off the flank, {S} misses the post.",
            "{S} drags the wing shot wide.",
            "The touchline run goes wide from {S}.",
            "{S} misses wide from the wing.",
        ],
        "mulch|wing|solo|over": [
            "{S} misses the wing shot over.",
            "Off the flank, {S} clears the bar.",
            "{S} lifts the wing shot over.",
            "The touchline run goes over from {S}.",
            "{S} misses over from the wing.",
        ],
        "mulch|through|pass|goal": [
            "{S} scores through the middle.",
            "{P} plays central and {S} scores.",
            "The channel goes in off {S}.",
            "{S} puts the middle ball in.",
            "A central pass, goal for {S}.",
        ],
        "mulch|through|pass|save": [
            "{K} saves the central shot.",
            "{P} plays the middle and {K} saves.",
            "The channel is saved by {K}.",
            "{K} keeps the middle ball out.",
            "{S} shoots central and {K} saves.",
        ],
        "mulch|through|pass|wide": [
            "{S} misses the channel wide.",
            "{P} plays central and {S} puts it wide.",
            "The middle ball goes wide off {S}.",
            "{S} hits the channel past the post.",
            "Through the middle, {S} misses wide.",
        ],
        "mulch|through|pass|over": [
            "{S} misses the channel over.",
            "{P} plays central and {S} puts it over.",
            "The middle ball goes over off {S}.",
            "{S} hits the channel over the bar.",
            "Through the middle, {S} misses over.",
        ],
        "mulch|through|solo|goal": [
            "{S} scores from the middle.",
            "{S} scores through the channel.",
            "The central run goes in for {S}.",
            "{S} puts the middle shot in.",
            "Straight through the middle, {S} scores.",
        ],
        "mulch|through|solo|save": [
            "{K} saves the middle shot.",
            "{K} saves the channel effort.",
            "The central run is saved by {K}.",
            "{K} keeps the middle shot out.",
            "{S} shoots through the middle and {K} saves.",
        ],
        "mulch|through|solo|wide": [
            "{S} misses the middle shot wide.",
            "Through the channel, {S} misses the post.",
            "{S} drags the central shot wide.",
            "The middle run goes wide from {S}.",
            "{S} misses wide from the channel.",
        ],
        "mulch|through|solo|over": [
            "{S} misses the middle shot over.",
            "Through the channel, {S} clears the bar.",
            "{S} lifts the central shot over.",
            "The middle run goes over from {S}.",
            "{S} misses over from the channel.",
        ],
        "mulch|counter|pass|goal": [
            "{S} scores on the break.",
            "{P} starts the counter and {S} scores.",
            "The break goes in off {S}.",
            "{S} puts the counter in.",
            "A counter, goal for {S}.",
        ],
        "mulch|counter|pass|save": [
            "{K} saves on the break.",
            "{P} starts the counter and {K} saves.",
            "The break is saved by {K}.",
            "{K} keeps the counter out.",
            "{S} shoots on the break and {K} saves.",
        ],
        "mulch|counter|pass|wide": [
            "{S} misses the break wide.",
            "{P} starts the counter and {S} puts it wide.",
            "The break goes wide off {S}.",
            "{S} hits the counter past the post.",
            "On the break, {S} misses wide.",
        ],
        "mulch|counter|pass|over": [
            "{S} misses the break over.",
            "{P} starts the counter and {S} puts it over.",
            "The break goes over off {S}.",
            "{S} hits the counter over the bar.",
            "On the break, {S} misses over.",
        ],
        "mulch|counter|solo|goal": [
            "{S} scores on the counter.",
            "{S} scores from the break.",
            "The counter goes in for {S}.",
            "{S} puts the break in the net.",
            "Away on the break, {S} scores.",
        ],
        "mulch|counter|solo|save": [
            "{K} saves the counter.",
            "{K} saves the break.",
            "The counter is saved by {K}.",
            "{K} keeps the break out.",
            "{S} shoots on the counter and {K} saves.",
        ],
        "mulch|counter|solo|wide": [
            "{S} misses the counter wide.",
            "On the break, {S} misses the post.",
            "{S} drags the break wide.",
            "The counter goes wide from {S}.",
            "{S} misses wide on the break.",
        ],
        "mulch|counter|solo|over": [
            "{S} misses the counter over.",
            "On the break, {S} clears the bar.",
            "{S} lifts the break over.",
            "The counter goes over from {S}.",
            "{S} misses over on the break.",
        ],
        "mulch|oneTwo|pass|goal": [
            "{S} scores from the one-two.",
            "{P} plays the one-two and {S} scores.",
            "The one-two goes in off {S}.",
            "{S} puts the one-two in.",
            "A one-two, goal for {S}.",
        ],
        "mulch|oneTwo|pass|save": [
            "{K} saves the one-two.",
            "{P} plays the one-two and {K} saves.",
            "The one-two is saved by {K}.",
            "{K} keeps the one-two out.",
            "{S} shoots the one-two and {K} saves.",
        ],
        "mulch|oneTwo|pass|wide": [
            "{S} misses the one-two wide.",
            "{P} plays the one-two and {S} puts it wide.",
            "The one-two goes wide off {S}.",
            "{S} hits the one-two past the post.",
            "After the one-two, {S} misses wide.",
        ],
        "mulch|oneTwo|pass|over": [
            "{S} misses the one-two over.",
            "{P} plays the one-two and {S} puts it over.",
            "The one-two goes over off {S}.",
            "{S} hits the one-two over the bar.",
            "After the one-two, {S} misses over.",
        ],
        "mulch|oneTwo|solo|goal": [
            "{S} scores off the one-two.",
            "{S} scores after the one-two.",
            "The one-two goes in for {S}.",
            "{S} puts that one-two in the net.",
            "After the one-two, {S} scores.",
        ],
        "mulch|oneTwo|solo|save": [
            "{K} saves that one-two.",
            "{K} saves after the one-two.",
            "That one-two is saved by {K}.",
            "{K} keeps that one-two out.",
            "{S} shoots after the one-two and {K} saves.",
        ],
        "mulch|oneTwo|solo|wide": [
            "{S} misses that one-two wide.",
            "The one-two misses the post from {S}.",
            "{S} drags the one-two wide.",
            "That one-two goes wide from {S}.",
            "{S} misses wide off the one-two.",
        ],
        "mulch|oneTwo|solo|over": [
            "{S} misses that one-two over.",
            "The one-two clears the bar from {S}.",
            "{S} lifts the one-two over.",
            "That one-two goes over from {S}.",
            "{S} misses over off the one-two.",
        ],
        "mulch|cutback|pass|goal": [
            "{S} scores from the cutback.",
            "{P} plays the cutback and {S} scores.",
            "The byline ball goes in off {S}.",
            "{S} puts the cutback in.",
            "A cutback, goal for {S}.",
        ],
        "mulch|cutback|pass|save": [
            "{K} saves the cutback.",
            "{P} plays the byline ball and {K} saves.",
            "The cutback is saved by {K}.",
            "{K} keeps the cutback out.",
            "{S} hits the cutback and {K} saves.",
        ],
        "mulch|cutback|pass|wide": [
            "{S} misses the cutback wide.",
            "{P} plays the cutback and {S} puts it wide.",
            "The byline ball goes wide off {S}.",
            "{S} hits the cutback past the post.",
            "From the byline, {S} misses wide.",
        ],
        "mulch|cutback|pass|over": [
            "{S} misses the cutback over.",
            "{P} plays the cutback and {S} puts it over.",
            "The byline ball goes over off {S}.",
            "{S} hits the cutback over the bar.",
            "From the byline, {S} misses over.",
        ],
        "mulch|cutback|solo|goal": [
            "{S} scores from the byline.",
            "{S} scores off the cutback.",
            "The cutback goes in for {S}.",
            "{S} puts the byline shot in.",
            "Off the byline, {S} scores.",
        ],
        "mulch|cutback|solo|save": [
            "{K} saves the byline shot.",
            "{K} saves the cutback effort.",
            "The byline shot is saved by {K}.",
            "{K} keeps the cutback shot out.",
            "{S} shoots from the byline and {K} saves.",
        ],
        "mulch|cutback|solo|wide": [
            "{S} misses the byline shot wide.",
            "Off the cutback, {S} misses the post.",
            "{S} drags the cutback wide.",
            "The byline run goes wide from {S}.",
            "{S} misses wide from the cutback.",
        ],
        "mulch|cutback|solo|over": [
            "{S} misses the byline shot over.",
            "Off the cutback, {S} clears the bar.",
            "{S} lifts the cutback over.",
            "The byline run goes over from {S}.",
            "{S} misses over from the cutback.",
        ],
        "mulch|penalty|solo|goal": [
            "{S} scores the penalty.",
            "{S} scores from the spot.",
            "The penalty goes in for {S}.",
            "{S} puts the penalty in.",
            "A spot-kick, goal for {S}.",
        ],
        "mulch|penalty|solo|save": [
            "{K} saves the penalty.",
            "{K} saves from the spot.",
            "The penalty is saved by {K}.",
            "{K} keeps the penalty out.",
            "The spot-kick is saved by {K}.",
        ],
        "mulch|penalty|solo|wide": [
            "{S} misses the penalty wide.",
            "{S} misses the spot, wide.",
            "The penalty goes wide off {S}.",
            "{S} puts the penalty past the post.",
            "{S} misses wide from the spot.",
        ],
        "mulch|penalty|solo|over": [
            "{S} misses the penalty over.",
            "{S} misses the spot, over.",
            "The penalty goes over off {S}.",
            "{S} puts the penalty over the bar.",
            "{S} misses over from the spot.",
        ],
    ]

    private static let leadBanks: [String: [String]] = [
        "pemberton|wing": [
            "{S}, in oceans of space.",
            "{P} crosses to {S}.",
            "{S}, waiting on the cross.",
            "From the flank, {S}.",
            "{S}, alone on the touchline.",
        ],
        "pemberton|through": [
            "{S}, through the middle.",
            "{P} plays central to {S}.",
            "{S}, in the channel.",
            "Through the middle, {S}.",
            "{S}, on the central ball.",
        ],
        "pemberton|counter": [
            "{S}, away on the break.",
            "{P} releases {S} on the counter.",
            "{S}, clean on the break.",
            "The counter, and {S}.",
            "{S}, with the break on.",
        ],
        "pemberton|oneTwo": [
            "{P} plays the one-two to {S}.",
            "{S}, onto the one-two.",
            "A one-two, and {S}.",
            "{S}, after the one-two.",
            "The one-two finds {S}.",
        ],
        "pemberton|cutback": [
            "{S}, from the byline.",
            "{P} cuts it back to {S}.",
            "{S}, on the cutback.",
            "From the byline to {S}.",
            "A cutback, and {S}.",
        ],
        "cobb|wing": [
            "{S}! He's got room!",
            "{S}! On the wing!",
            "{P} crosses to {S}!",
            "{S}! Cross coming!",
            "{S}! On the flank!",
        ],
        "cobb|through": [
            "{S}! Through the middle!",
            "{S}! The channel!",
            "{P} plays {S} central!",
            "{S}! In the middle!",
            "{S}! Central ball!",
        ],
        "cobb|counter": [
            "{S}! On the break!",
            "{S}! The counter!",
            "{S}! What a break!",
            "{S}! Hit the break!",
            "{S}! Counter time!",
        ],
        "cobb|oneTwo": [
            "{S}! The one-two!",
            "{S}! One-two on!",
            "{S}! Nice one-two!",
            "{S}! After the one-two!",
            "{S}! One-two time!",
        ],
        "cobb|cutback": [
            "{S}! On the byline!",
            "{S}! Cutback there!",
            "{P} cuts to {S}!",
            "{S}! From the byline!",
            "{S}! The cutback!",
        ],
        "mulch|wing": [
            "{S}, who is out on the wing.",
            "{P} crosses toward {S}.",
            "{S}, standing near the cross.",
            "The flank, and also {S}.",
            "{S}, by the touchline somewhere.",
        ],
        "mulch|through": [
            "{S}, through the middle somehow.",
            "{P} plays the channel to {S}.",
            "{S}, central, more or less.",
            "Through the middle, that is {S}.",
            "{S}, in the channel I think.",
        ],
        "mulch|counter": [
            "{S}, who has gone on the break.",
            "{P} starts a counter for {S}.",
            "{S}, running the break now.",
            "A counter, I believe, {S}.",
            "{S}, away with the counter.",
        ],
        "mulch|oneTwo": [
            "{S}, after some one-two.",
            "{P} does a one-two with {S}.",
            "The one-two, then {S}.",
            "{S}, on the end of a one-two.",
            "A one-two happens for {S}.",
        ],
        "mulch|cutback": [
            "{S}, near the byline.",
            "{P} offers a cutback to {S}.",
            "{S}, waiting on the cutback.",
            "From the byline, apparently {S}.",
            "A cutback, and there is {S}.",
        ],
    ]

    private static let asideBanks: [String: [String]] = [
        "pemberton|wing": [
            "A look of mystification on the angular face of {S}.",
            "A faintly bewildered hush follows the cross.",
            "Quite the most unhurried ball from the wing.",
            "One sensed the flank had been left alone.",
            "A rather ornate calm along the touchline.",
        ],
        "pemberton|through": [
            "A look of mystification through the middle.",
            "A faintly bewildered hush in the channel.",
            "Quite the straightest central path today.",
            "The middle, and a rather solemn hush.",
            "One watched the channel with folded arms.",
        ],
        "pemberton|counter": [
            "A look of mystification as the break develops.",
            "A faintly bewildered hush greets the counter.",
            "Quite the most spacious break of the afternoon.",
            "The counter draws a rather studied silence.",
            "One noted the break with a raised brow.",
        ],
        "pemberton|oneTwo": [
            "A look of mystification at the one-two.",
            "A faintly bewildered hush follows the one-two.",
            "Quite the neatest one-two of the half.",
            "The one-two draws a rather knowing nod.",
            "One admired the one-two from a distance.",
        ],
        "pemberton|cutback": [
            "A look of mystification at the cutback.",
            "A faintly bewildered hush at the byline.",
            "Quite the most deliberate cutback one recalls.",
            "The byline, and a rather composed pause.",
            "One studied the cutback with quiet interest.",
        ],
        "mulch|wing": [
            "Like a fridge racing a lawnmower on the wing.",
            "I had a thought about the cross and it left.",
            "Which is a swan on the touchline, or a meter.",
            "The flank reminded me of a lost toaster.",
            "A wing is a bird, and this was similar.",
        ],
        "mulch|through": [
            "Like a fridge through the middle of a picnic.",
            "I had a thought in the channel and it drowned.",
            "Which is a swan, central, or a parking meter.",
            "The middle reminded me of a hallway at home.",
            "A channel is for boats, and also {S}.",
        ],
        "mulch|counter": [
            "Like a fridge winning the break against a cloud.",
            "I had a thought about the counter and lost it.",
            "Which is a parking meter on the break.",
            "The counter reminded me of an angry kettle.",
            "A break is a holiday, which this was not.",
        ],
        "mulch|oneTwo": [
            "Like a fridge playing a one-two with a stool.",
            "I had a one-two of a thought and lost both.",
            "Which is a parking meter in a one-two.",
            "The one-two reminded me of twin toasters.",
            "A one-two is a dance, badly remembered.",
        ],
        "mulch|cutback": [
            "Like a fridge doing a cutback at a picnic.",
            "I had a thought at the byline and misplaced it.",
            "Which is a swan attempting a cutback.",
            "The byline reminded me of a kitchen drawer.",
            "A cutback is a refund, or this pass.",
        ],
    ]
}
