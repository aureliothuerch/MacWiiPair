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
codesign --force --sign - "$APP"
echo "Built $APP"
