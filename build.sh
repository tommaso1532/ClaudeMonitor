#!/bin/bash
# Build ClaudeMonitor.app (unsandboxed app producer + sandboxed widget), then DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if command -v xcodegen >/dev/null 2>&1; then
  echo "▸ generate project"
  xcodegen generate >/dev/null
else
  echo "▸ xcodegen not found; using existing ClaudeMonitor.xcodeproj"
fi

echo "▸ build app + widget"
xcodebuild -project ClaudeMonitor.xcodeproj -scheme ClaudeMonitor \
  -configuration Release -derivedDataPath build -allowProvisioningUpdates build \
  >/tmp/claude-monitor-build.log 2>&1 || { tail -40 /tmp/claude-monitor-build.log; exit 1; }

APP="$ROOT/build/Build/Products/Release/ClaudeMonitor.app"
codesign --verify --strict "$APP" && echo "  signature OK"

echo "▸ DMG"
bash "$ROOT/make-dmg.sh" "$APP"
echo "✓ done"
