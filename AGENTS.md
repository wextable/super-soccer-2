# SuperSoccer2 — read this first

iPhone and iPad soccer management. TCA, SwiftUI, and Swift concurrency. iOS 18+, Swift 6. The user plays as Manchester City or Norwich City. The week is four tabs — Club, Table, Week, and Match — on iPhone and iPad. Kickoff covers the tabs with the highlight reel, then full-time stats. The other fixtures that week are scorelines, and the table records the week when you come back. There is no second season.

## Git

Start new work on a new branch from `main`. The user pushes, opens pull requests, and merges. Do not push or open a pull request unless the user asks.

## Where the game lives

- Match function: `MatchSimulator.simulate` in `SuperSoccer2/Domain/MatchSimulator.swift`. Same squads and seed, same match. Do not change the sim formulas unless asked.
- Names: `SuperSoccer2/Domain/NameGenerator.swift`. The list and the rolls come from the old app.
- Draft: `SuperSoccer2/Domain/LeagueDraft.swift`. A launch builds the twenty-club pool and tier draft. Club selection still offers only Manchester City and Norwich City. The week uses every club and `seasonFixtures`.
- Week: `MatchweekFeature` and `LeagueTable`. Four tabs: Club (a player pushes a detail screen), Table, Week (fixtures and results), and Match (opponent, ratings, key players, kickoff). The week opens on Club. A table row pushes that same team screen. Leaders list ten names until the rest are shown. The week button says Advance week. A key player opens the same player detail. When the 38-week list is finished there is no next fixture, and the championship screen names the champion and that club’s leaders. The finished season stores the champion and six awards. Points are 3 for a win and 1 for a draw. The table sorts by points, then goal difference, then `Club.overall`. The table updates when the reel is left early or when full-time stats is dismissed. Full time can also go straight back to the week. Simulate match records the fixture without the reel. Debug builds can simulate the remaining weeks after a confirmation.
- Season check, not a second screen: `SuperSoccer2/Domain/SeasonHarness.swift`.
- Theme: `SuperSoccer2/Theme.swift`. Screens read `Theme` from the SwiftUI environment. A new look replaces `Theme.starbyte` in `AppView` (`SuperSoccer2/App/SuperSoccer2App.swift`). Do not put colors in a reducer.

## Ratings

Player overall is the position blend on `Player`. Team overall is the rounded mean of team attack and team defense, clamped to 1–99, on `Club`. The match reads attack and defense, not either overall.

## Skills

Read these from `~/.cursor/skills` when the work touches them:

- `ios-design-agent-skill` — iOS design
- `swift-concurrency` — Swift concurrency
- `rusel95-ios-agent-skills-tca-swiftui-1.0.1` — TCA and SwiftUI

## Old app

https://github.com/wextable/soccer is the reference for names, ratings, and match math. It is not a codebase to extend. https://github.com/wextable/superSoccer is not a source.
