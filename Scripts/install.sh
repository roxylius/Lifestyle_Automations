#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="GlassReminders"
APP_DIR="$HOME/Applications/$APP_NAME.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/$APP_NAME"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.pocketfm.glass-reminders.plist"
TEMPLATE="$ROOT_DIR/LaunchAgents/com.pocketfm.glass-reminders.plist.template"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer only supports macOS." >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift was not found. Install Apple Command Line Tools first:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

echo "Building $APP_NAME..."
swift build -c release --package-path "$ROOT_DIR"

echo "Installing app bundle to $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/.build/release/$APP_NAME" "$EXECUTABLE"
cp -R "$ROOT_DIR/Resources/Animations" "$APP_DIR/Contents/Resources/"
cp -R "$ROOT_DIR/Resources/Sounds" "$APP_DIR/Contents/Resources/"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.pocketfm.glass-reminders</string>
  <key>CFBundleName</key>
  <string>Glass Reminders</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "Writing LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed \
  -e "s#__APP_EXECUTABLE__#$EXECUTABLE#g" \
  -e "s#__HOME__#$HOME#g" \
  "$TEMPLATE" > "$LAUNCH_AGENT"

echo "Loading LaunchAgent..."
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$(id -u)/com.pocketfm.glass-reminders"

echo "Installed."
echo "Open it with: open \"$APP_DIR\""
echo "Use the droplet menu-bar icon to open settings."
