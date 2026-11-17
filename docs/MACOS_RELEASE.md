# macOS release: universal, signed and notarized

Without a Developer ID signature and Apple notarization, macOS refuses to
open a downloaded app ("cannot be opened because the developer cannot be
verified"). This page is the procedure; the release checklist links here.

## One-time setup (needs an active Apple Developer Program membership)

1. **Developer ID certificate.** In Xcode → Settings → Accounts → your team →
   Manage Certificates → `+` → *Developer ID Application*. It lands in your
   login keychain. Check it and note its full name and team id:

   ```sh
   security find-identity -v -p codesigning
   ```

   e.g. `Developer ID Application: Jane Doe (TEAMID1234)`.

2. **Notarization key.** App Store Connect → Users and Access → Integrations →
   App Store Connect API → generate a key with the *Developer* role. Download
   the `.p8` once (it cannot be downloaded again) and keep it outside the
   repository. Note the *Key ID* and the *Issuer ID*.

Never commit the certificate, the `.p8` file or these identifiers.

## Build

[`scripts/build-macos.sh`](../scripts/build-macos.sh) builds the universal app,
embeds the widget, signs everything with the hardened runtime and a secure
timestamp, packages the DMG, then submits it to Apple and staples the ticket:

```sh
UNIVERSAL=1 NOTARIZE=1 \
SIGN_IDENTITY="Developer ID Application: Jane Doe (TEAMID1234)" \
TEAM_ID=TEAMID1234 \
APPLE_API_KEY=<key id> \
APPLE_API_ISSUER=<issuer id> \
APPLE_API_KEY_PATH="$HOME/.keys/AuthKey_<key id>.p8" \
DMG_OUT="$PWD/dist/MediaFlow-macOS-universal.dmg" \
scripts/build-macos.sh
```

## Verify before publishing

```sh
APP=target/universal-apple-darwin/release/bundle/macos/MediaFlow.app
DMG=dist/MediaFlow-macOS-universal.dmg
lipo -archs "$APP/Contents/MacOS/mediaflow-app"   # x86_64 arm64
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose "$APP"    # source=Notarized Developer ID
xcrun stapler validate "$DMG"
shasum -a 256 "$DMG"                              # publish this checksum
```

Then download the `.dmg` through a browser on another Mac (or a fresh user
account), so it carries the quarantine flag, and open it: it must launch
without any warning.
