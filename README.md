# ClaudeMonitor

ClaudeMonitor is a macOS menu bar app and desktop widget for monitoring Claude account usage across multiple `cswap` accounts.

It shows the active account, 5 hour usage, 7 day usage, reset countdowns, and running Claude instances. The app is intentionally small: it does not replace `cswap`; it reads `cswap --list`, parses the output, and publishes a local JSON snapshot that the widget can read.

## Requirements

- macOS 14 Sonoma or newer
- Xcode command line tools if building from source
- [Homebrew](https://brew.sh/) for the install commands below
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) if regenerating the Xcode project
- [`cswap`](https://pypi.org/project/claude-swap/) from the `claude-swap` package

Install build dependencies and the `cswap` dependency:

```bash
brew install xcodegen uv
uv tool install claude-swap
cswap --version
```

ClaudeMonitor looks for `cswap` in these locations:

```text
~/.local/bin/cswap
/opt/homebrew/bin/cswap
/usr/local/bin/cswap
```

## Claude Code Prompt

Paste this into Claude Code from any working folder:

```text
Clone https://github.com/tommaso1532/ClaudeMonitor.git and make ClaudeMonitor fully installed on this Mac. Install any missing local dependencies needed to build and run it, including Xcode command line tools, Homebrew, xcodegen, uv, and the claude-swap/cswap CLI. Run ./build.sh, mount the generated ClaudeMonitor.dmg, quit any running ClaudeMonitor app, copy ClaudeMonitor.app into /Applications replacing any older ClaudeMonitor.app, unmount the image, launch /Applications/ClaudeMonitor.app, and verify that cswap --version works and the app is running. Keep everything local to my machine; do not publish, commit, or push anything.
```

## Build And Install Locally

Clone the repo and run the build script:

```bash
git clone https://github.com/tommaso1532/ClaudeMonitor.git
cd ClaudeMonitor
./build.sh
```

Then install the generated app:

```bash
APP_MOUNT="$(mktemp -d /tmp/ClaudeMonitor.XXXXXX)"
osascript -e 'quit app "ClaudeMonitor"' || true
hdiutil attach dist/ClaudeMonitor.dmg -mountpoint "$APP_MOUNT" -quiet
rm -rf /Applications/ClaudeMonitor.app
cp -R "$APP_MOUNT/ClaudeMonitor.app" /Applications/
hdiutil detach "$APP_MOUNT" -quiet
rmdir "$APP_MOUNT" 2>/dev/null || true
open /Applications/ClaudeMonitor.app
```

## How It Works With cswap

ClaudeMonitor depends on the `cswap` CLI for account state. Internally it runs:

```bash
cswap --list
```

It parses the `Accounts:` and `Running instances:` sections from that output. The parsing is implemented in:

```text
Sources/Shared/Producer.swift
```

The data model mirrors the JSON shape used by the earlier `cswap-monitor` script:

```json
{
  "ok": true,
  "ts": "2026-06-15T00:00:00Z",
  "settings": {
    "cswapPath": "~/.local/bin/cswap",
    "mode": "both",
    "refreshSeconds": 300
  },
  "accounts": [],
  "instances": []
}
```

The app writes the latest snapshot to:

```text
~/Library/Application Support/ClaudeMonitor/data.json
~/Library/Containers/app.claudemonitor.ClaudeMonitor.ClaudeWidget/Data/data.json
```

The widget reads from its sandbox container and refreshes through WidgetKit timelines.

## Project Structure

```text
App/                         App Info.plist
Widget/                      Widget Info.plist and entitlements
Sources/App/                 SwiftUI app, settings window, menu bar UI
Sources/Widget/              WidgetKit provider and widget views
Sources/Shared/              cswap parsing, data model, shared styling
Resources/Assets.xcassets/   App icon, widget/menu assets, accent color
Resources/Source/            Source SVGs used to generate icon assets
project.yml                  XcodeGen project definition
build.sh                     Local build and packaging entrypoint
```
