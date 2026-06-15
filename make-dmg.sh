#!/bin/bash
# Package ClaudeMonitor.app into a drag-to-install DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-$ROOT/build/Build/Products/Release/ClaudeMonitor.app}"
OUT="$ROOT/dist/ClaudeMonitor.dmg"

mkdir -p "$ROOT/dist"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
if [[ -f "$APP/Contents/Resources/AppIcon.icns" ]]; then
  cp "$APP/Contents/Resources/AppIcon.icns" "$STAGE/.VolumeIcon.icns"
  SetFile -a C "$STAGE"
fi

rm -f "$OUT"
hdiutil create -volname "ClaudeMonitor" -srcfolder "$STAGE" \
  -ov -format UDZO "$OUT" >/dev/null
rm -rf "$STAGE"
echo "  DMG → $OUT"
