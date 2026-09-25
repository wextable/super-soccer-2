# SuperSoccer2 — read this first

iPhone and iPad soccer management. TCA, SwiftUI, and Swift concurrency. iOS 18+, Swift 6. The slice is two clubs, one match, one highlight. There is no league screen.

## Git

Start new work on a new branch from `main`. The user pushes, opens pull requests, and merges. Do not push or open a pull request unless the user asks.

## Where the game lives

- Match function: `MatchSimulator.simulate` in `SuperSoccer2/Domain/MatchSimulator.swift`. Same squads and seed, same match. Do not change the sim formulas unless asked.
- Names: `SuperSoccer2/Domain/NameGenerator.swift`. The list and the rolls come from the old app.
- Draft: `SuperSoccer2/Domain/LeagueDraft.swift`. A launch builds the twenty-club pool and tier draft, then the screen keeps Manchester City and Norwich City.
- Season check, not a screen: `SuperSoccer2/Domain/SeasonHarness.swift`.
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
