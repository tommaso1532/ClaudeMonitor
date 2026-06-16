# Local Install

From a fresh working folder, clone and build the app:

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

For the one-shot Claude Code prompt, see the root `README.md`.
