#!/usr/bin/env bash
# Build MediaFlow.app with the WidgetKit extension embedded, sign it and
# (optionally) package a DMG. Run on macOS 14+ with Xcode, Rust and Node.
#
#   scripts/build-macos.sh                 # ad-hoc signed (local testing)
#   SIGN_IDENTITY="Apple Development: …" TEAM_ID=ABCDE12345 scripts/build-macos.sh
#   UNIVERSAL=1 scripts/build-macos.sh     # Apple Silicon + Intel in one app
#   Release (Developer ID, notarized; see docs/MACOS_RELEASE.md):
#   UNIVERSAL=1 NOTARIZE=1 SIGN_IDENTITY="Developer ID Application: …" \
#     TEAM_ID=… APPLE_API_KEY=… APPLE_API_ISSUER=… APPLE_API_KEY_PATH=… \
#     scripts/build-macos.sh
#
# Ad-hoc signing is enough for the app, the menu-bar icon, Dock progress and
# notifications. macOS only shows widgets whose extension is signed with a
# real team identity (free Apple ID in Xcode works for your own Mac).
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
IDENTITY="${SIGN_IDENTITY:--}"
# A Developer ID signature needs a secure timestamp to be notarized; an
# ad-hoc signature ("-") cannot have one.
if [[ "$IDENTITY" == "-" ]]; then TIMESTAMP=--timestamp=none; else TIMESTAMP=--timestamp; fi
DMG="${DMG:-1}"
UNIVERSAL="${UNIVERSAL:-0}"

command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen" >&2; exit 1; }

echo "==> Desktop app"
if [[ "$UNIVERSAL" == "1" ]]; then
  rustup target add aarch64-apple-darwin x86_64-apple-darwin
  (cd app && npm ci && npx tauri build --bundles app --target universal-apple-darwin)
  APP="$ROOT/target/universal-apple-darwin/release/bundle/macos/MediaFlow.app"
  WIDGET_ARCHS=(ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO)
else
  (cd app && npm ci && npx tauri build --bundles app)
  APP="$ROOT/target/release/bundle/macos/MediaFlow.app"
  WIDGET_ARCHS=()
fi
[[ -d "$APP" ]] || { echo "app bundle not found: $APP" >&2; exit 1; }

echo "==> Widget extension"
(cd app/macos-widget && xcodegen generate --quiet)
EXTRA=()
if [[ -n "${TEAM_ID:-}" ]]; then EXTRA+=(DEVELOPMENT_TEAM="$TEAM_ID"); fi
xcodebuild -quiet -project app/macos-widget/MediaFlowWidget.xcodeproj -scheme MediaFlowWidget \
  -configuration Release -derivedDataPath "$ROOT/target/widget" \
  CODE_SIGNING_ALLOWED=NO ${EXTRA[@]+"${EXTRA[@]}"} ${WIDGET_ARCHS[@]+"${WIDGET_ARCHS[@]}"} build
APPEX="$ROOT/target/widget/Build/Products/Release/MediaFlowWidget.appex"

echo "==> Embed and sign"
mkdir -p "$APP/Contents/PlugIns"
rm -rf "$APP/Contents/PlugIns/MediaFlowWidget.appex"
cp -R "$APPEX" "$APP/Contents/PlugIns/"
# Inner code first, then the app.
codesign --force --options runtime "$TIMESTAMP" -s "$IDENTITY" \
  --entitlements app/macos-widget/Widget/MediaFlowWidget.entitlements \
  "$APP/Contents/PlugIns/MediaFlowWidget.appex"
codesign --force --options runtime "$TIMESTAMP" -s "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"
echo "Signed: $APP (identity: $IDENTITY)"

if [[ "$DMG" == "1" ]]; then
  OUT="${DMG_OUT:-$ROOT/target/release/MediaFlow-macos.dmg}"
  mkdir -p "$(dirname "$OUT")"
  rm -f "$OUT"
  STAGE=$(mktemp -d)
  cp -R "$APP" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create -quiet -volname MediaFlow -srcfolder "$STAGE" -ov -format UDZO "$OUT"
  rm -rf "$STAGE"
  echo "DMG: $OUT"

  # Notarization (Developer ID + App Store Connect API key). See
  # docs/MACOS_RELEASE.md. Without it, Gatekeeper blocks downloaded builds.
  if [[ "${NOTARIZE:-0}" == "1" ]]; then
    : "${APPLE_API_KEY:?set APPLE_API_KEY (key id)}"
    : "${APPLE_API_ISSUER:?set APPLE_API_ISSUER (issuer id)}"
    : "${APPLE_API_KEY_PATH:?set APPLE_API_KEY_PATH (path to the .p8 file)}"
    echo "==> Notarize"
    codesign --force --timestamp -s "$IDENTITY" "$OUT"
    xcrun notarytool submit "$OUT" --key "$APPLE_API_KEY_PATH" \
      --key-id "$APPLE_API_KEY" --issuer "$APPLE_API_ISSUER" --wait
    xcrun stapler staple "$OUT"
    xcrun stapler validate "$OUT"
    echo "Notarized: $OUT"
  fi
fi
