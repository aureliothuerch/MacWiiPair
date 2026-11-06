#!/bin/bash
# Builds the app and packs it into a DMG for a GitHub release: build/MacWiiPair-<version>.dmg
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
DMG="build/MacWiiPair-$VERSION.dmg"
STAGE="$(mktemp -d)/MacWiiPair"
mkdir -p "$STAGE"
ditto build/MacWiiPair.app "$STAGE/MacWiiPair.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "MacWiiPair" -srcfolder "$STAGE" -format UDZO -ov "$DMG" > /dev/null
echo "Wrote $DMG"
