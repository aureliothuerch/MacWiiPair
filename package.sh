#!/bin/bash
# Builds build/MacWiiPair-<version>.dmg.
#
#   ./package.sh                                   ad-hoc signed, for local use
#   SIGN_ID=... NOTARY_PROFILE=... ./package.sh    signed, notarized and stapled
#
# Create the notary profile once: xcrun notarytool store-credentials <name>
set -euo pipefail
cd "$(dirname "$0")"
export SIGN_ID="${SIGN_ID:--}"

notarize() {
    local out
    out="$(xcrun notarytool submit "$1" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)"
    echo "$out"
    echo "$out" | grep -q "status: Accepted" || { echo "Notarization failed" >&2; exit 1; }
}

./build.sh
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
DMG="build/MacWiiPair-$VERSION.dmg"

if [ -n "${NOTARY_PROFILE:-}" ]; then
    ditto -c -k --keepParent build/MacWiiPair.app build/notarize.zip
    notarize build/notarize.zip
    rm build/notarize.zip
    xcrun stapler staple build/MacWiiPair.app
fi

STAGE="$(mktemp -d)/MacWiiPair"
mkdir -p "$STAGE"
ditto build/MacWiiPair.app "$STAGE/MacWiiPair.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "MacWiiPair" -srcfolder "$STAGE" -format UDZO -ov "$DMG" > /dev/null

if [ "$SIGN_ID" != "-" ]; then
    codesign --force --timestamp --sign "$SIGN_ID" "$DMG"
fi
if [ -n "${NOTARY_PROFILE:-}" ]; then
    notarize "$DMG"
    xcrun stapler staple "$DMG"
fi
echo "Wrote $DMG"
