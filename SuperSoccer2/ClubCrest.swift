import SwiftUI
import UIKit

/// Club crests copied from the previous app. A club with no picture draws nothing.
enum ClubCrests {
    static let assetNames: [String: String] = [
        "manchester-city": "team_icon_manchester_city",
        "liverpool": "team_icon_liverpool",
        "chelsea": "team_icon_chelsea",
        "arsenal": "team_icon_arsenal",
        "manchester-united": "team_icon_manchester_united",
        "west-ham": "team_icon_west_ham",
        "tottenham": "team_icon_tottenham",
        "wolverhampton": "team_icon_wolverhampton",
        "leicester-city": "team_icon_leicester_city",
        "crystal-palace": "team_icon_crystal_palace",
        "brighton": "team_icon_brighton",
        "aston-villa": "team_icon_aston_villa",
        "southampton": "team_icon_southampton",
        "brentford": "team_icon_brentford",
        "everton": "team_icon_everton",
        "leeds-united": "team_icon_leeds_united",
        "watford": "team_icon_watford",
        "burnley": "team_icon_burnley",
        "newcastle-united": "team_icon_newcastle",
        "norwich-city": "team_icon_norwich_city",
    ]

    static func assetName(for clubID: String) -> String? {
        assetNames[clubID]
    }

    /// Missing art returns nil. Callers leave the name on its own.
    @MainActor
    static func image(for clubID: String) -> UIImage? {
        guard let name = assetName(for: clubID) else { return nil }
        if let image = UIImage(named: name) { return image }
        guard let bundle = Bundle(identifier: "dev.personal.SuperSoccer2") else { return nil }
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}

/// The crest beside a club name. Nothing is drawn when the catalog has no match.
struct ClubCrest: View {
    @Environment(\.theme) private var theme
    var clubID: String
    var scale: Scale = .row

    enum Scale {
        case row
        case mark
    }

    var body: some View {
        if let image = ClubCrests.image(for: clubID) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: length, height: length)
                .accessibilityHidden(true)
        }
    }

    private var length: CGFloat {
        switch scale {
        case .row: theme.metrics.crest
        case .mark: theme.metrics.crestMark
        }
    }
}
