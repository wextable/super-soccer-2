# SuperSoccer2

Start here. iPhone and iPad soccer management, built with TCA and SwiftUI.

## Git

New work branches from `main`. The user pushes and opens pull requests. Agents do not push or open a pull request unless asked.

## Tests

On this machine, Xcode is `/Applications/Xcode.app`. Use a fresh derived-data directory and turn explicit modules off:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
rm -rf /tmp/SuperSoccer2Derived
xcodebuild test \
  -project SuperSoccer2.xcodeproj \
  -scheme SuperSoccer2 \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/SuperSoccer2Derived \
  -skipMacroValidation \
  -skipPackagePluginValidation \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
```

## Where things live

`AppView` in `SuperSoccer2/App/SuperSoccer2App.swift` installs the theme (`Theme.starbyte` from `SuperSoccer2/Theme.swift`). Screens read `Theme` from the environment.

`WeekTuning` is `SuperSoccer2/Domain/WeekTuning.swift`.

The week is four tabs — Club, Table, Week, and Match — in `SuperSoccer2/Matchweek/MatchweekView.swift`.

Each screen is its own folder: the reducer, the view, and types only that screen uses.

- `App`
- `ClubSelection`
- `Matchweek`
- `Team`
- `PlayerDetail`
- `Highlight`
- `MatchStats`
- `Leaders`
- `Championship`

Shared code stays shared. The match function is `MatchSimulator.simulate` in `SuperSoccer2/Domain/MatchSimulator.swift`. Clubs, players, the draft, and the table stay in `SuperSoccer2/Domain/`. `WeekCard` and `WeekHairline` are in `SuperSoccer2/WeekChrome.swift`.

Read these from `~/.cursor/skills` when the work touches them: `ios-design-agent-skill`, `swift-concurrency`, `rusel95-ios-agent-skills-tca-swiftui-1.0.1`.
