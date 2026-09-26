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

From the repo root. Xcode is `/Applications/Xcode.app`. A fresh derived-data directory and explicit modules off are required on this machine; a plain `xcodebuild test` fails here.

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

`iPhone 17` is an installed simulator. `-skipMacroValidation` and `-skipPackagePluginValidation` let the Swift package macros build.
