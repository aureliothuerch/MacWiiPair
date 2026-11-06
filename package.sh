#!/bin/bash
# Builds the app and zips it for a GitHub release: build/MacWiiPair-<version>.zip
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
ditto -c -k --keepParent build/MacWiiPair.app "build/MacWiiPair-$VERSION.zip"
echo "Wrote build/MacWiiPair-$VERSION.zip"
