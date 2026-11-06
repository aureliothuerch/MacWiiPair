#!/bin/bash
# Builds Resources/AppIcon.icns from Resources/AppIcon-1024.png (macOS only).
set -euo pipefail
cd "$(dirname "$0")/.."
SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"
for s in 16 32 128 256 512; do
    sips -z "$s" "$s" Resources/AppIcon-1024.png --out "$SET/icon_${s}x${s}.png" > /dev/null
    sips -z "$((s * 2))" "$((s * 2))" Resources/AppIcon-1024.png --out "$SET/icon_${s}x${s}@2x.png" > /dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
echo "Wrote Resources/AppIcon.icns"
