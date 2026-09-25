# SuperSoccer2

An iPhone and iPad soccer management game. You take Manchester City or Norwich City. The week is four tabs: Club, Table, Week, and Match. Kickoff plays your fixture, then a full-time stats screen, and the other matches that week land on the table. The match is simulated. You do not control a player on the ball.

## Open and run

Open `SuperSoccer2.xcodeproj` and run the `SuperSoccer2` scheme on an iPhone or iPad simulator. The app target is iOS 18.

`xcode-select` on this machine may point at the Command Line Tools, which do not include `xcodebuild` or `simctl`. The known-good build uses Xcode at `/Applications/Xcode.app`:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export PATH="$DEVELOPER_DIR/usr/bin:$PATH"
```

## Tests

From the repo root, with `DEVELOPER_DIR` set as above:

```sh
xcodebuild test \
  -project SuperSoccer2.xcodeproj \
  -scheme SuperSoccer2 \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skipMacroValidation \
  -skipPackagePluginValidation
```

`iPhone 17` is an installed simulator. `-skipMacroValidation` and `-skipPackagePluginValidation` are required here so the Swift package macros are allowed to build.
