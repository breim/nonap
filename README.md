# NoNap

Menu bar macOS app that prevents the Mac from sleeping while it is active. It can also keep the display on when enabled from the menu.

## Build

Open `NoNap.xcodeproj` in Xcode and run the `NoNap` scheme.

From Terminal:

```sh
xcodebuild -project NoNap.xcodeproj -scheme NoNap -configuration Debug -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

Run the built app:

```sh
open build/Build/Products/Debug/NoNap.app
```

## Open at Login

Use the `Open at Login` menu item in the app's menu bar menu. If macOS shows `Needs Approval`, approve NoNap in System Settings > General > Login Items & Extensions.

## GitHub Download Build

GitHub Actions builds `NoNap-macOS.dmg` on every push to `main` and uploads it as a workflow artifact.

To publish a public release download, create and push a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The release workflow attaches `NoNap-macOS.dmg` to the GitHub release. Open the DMG, then drag `NoNap.app` to `Applications`.

## Verify the power assertion

Run this while the app is active:

```sh
pmset -g assertions
```

You should see a `PreventUserIdleSystemSleep` assertion with the name `NoNap is keeping your Mac awake`. If `Keep Display On` is enabled, you should also see a `PreventUserIdleDisplaySleep` assertion. They should disappear when you deactivate the app, when a selected timer expires, or when you quit the app.
