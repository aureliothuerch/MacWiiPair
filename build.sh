#!/bin/bash
# Builds build/MacWiiPair.app (ad-hoc signed). Needs Xcode or the Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
APP=build/MacWiiPair.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/MacWiiPair" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# SIGN_ID unset: ad-hoc signature for local builds.
# SIGN_ID="Developer ID Application: ...": hardened runtime for notarization.
SIGN_ID="${SIGN_ID:--}"
if [ "$SIGN_ID" = "-" ]; then
    codesign --force --sign - "$APP"
else
    codesign --force --options runtime --timestamp \
        --entitlements Resources/MacWiiPair.entitlements --sign "$SIGN_ID" "$APP"
fi
echo "Built $APP"
