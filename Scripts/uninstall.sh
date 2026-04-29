#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/Applications/GlassReminders.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.pocketfm.glass-reminders.plist"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This uninstaller only supports macOS." >&2
  exit 1
fi

echo "Stopping LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true

echo "Removing app and LaunchAgent..."
rm -rf "$APP_DIR"
rm -f "$LAUNCH_AGENT"

echo "Uninstalled app files."
echo "Reminder config is still stored at:"
echo "  $HOME/Library/Application Support/GlassReminders"
echo "Remove that folder manually if you also want to delete reminder data."
