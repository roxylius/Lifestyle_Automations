# Glass Reminders

Glass Reminders is a native macOS menu-bar app for lifestyle reminders. It
shows a centered translucent glass popup with an animated GIF, voice prompt,
optional custom audio, and action buttons.

The app currently ships with two default reminders:

- Drink water every 90 minutes between 8:00 AM and 10:00 PM.
- Put eye drops at 8:00 AM, 11:00 AM, 1:15 PM, 2:00 PM, 5:00 PM, 8:00 PM, and
  8:30 PM.

This is a personal reminder utility, not medical guidance. Change the eye-drop
schedule to match your own doctor's instructions.

## Features

- Native macOS menu-bar app.
- Centered transparent glass reminder popup.
- Animated GIF reminders for water and eye drops.
- Voice prompt at configurable volume.
- Custom audio file picker for each reminder.
- Custom GIF/PNG picker for each reminder.
- Add, edit, disable, delete, test, snooze, or skip reminders.
- Local-only storage in `~/Library/Application Support/GlassReminders`.
- LaunchAgent install so the app starts at login.

## Requirements

- macOS 13 or newer.
- Apple Command Line Tools or Xcode with Swift installed.

Check Swift:

```sh
swift --version
```

If Swift is missing, install Apple's command line tools:

```sh
xcode-select --install
```

## Install

Clone the repo and run the installer:

```sh
git clone https://github.com/roxylius/Lifestyle_Automations.git
cd Lifestyle_Automations
./Scripts/install.sh
```

The installer builds the release binary and creates:

- `~/Applications/GlassReminders.app`
- `~/Library/LaunchAgents/com.pocketfm.glass-reminders.plist`
- `~/Library/Application Support/GlassReminders/reminders.json`
- `~/Library/Application Support/GlassReminders/state.json`

## Open The App

Glass Reminders is a menu-bar app, so it may not appear in the Dock.

Open it from Terminal:

```sh
open ~/Applications/GlassReminders.app
```

Or search Spotlight for:

```text
Glass Reminders
```

After opening it, click the droplet icon in the macOS menu bar. The menu has:

- `Open Settings`
- `Test Water Reminder`
- `Test Eye Drops Reminder`
- `Reveal Config Folder`
- `Quit`

## Configure Reminders

Open `Open Settings` from the droplet menu-bar icon.

You can edit:

- Reminder title and message.
- Schedule type: interval, fixed times, or mixed.
- Start/end active window.
- Nag interval.
- Snooze duration.
- Voice text.
- GIF/PNG animation.
- Custom sound file.
- Volume.

Custom GIFs, PNGs, and audio files are copied into:

```text
~/Library/Application Support/GlassReminders/Assets
```

This means the reminder keeps working even if the original file is moved from
Downloads.

## Default Assets

The bundled default GIFs live in:

```text
Resources/Animations/drink-water.gif
Resources/Animations/cat-eye-drops.gif
```

The installer copies them into the app bundle at:

```text
~/Applications/GlassReminders.app/Contents/Resources/Animations
```

## Run Without Installing

From the repo root:

```sh
swift run GlassReminders
```

This is useful while developing, but the LaunchAgent login behavior only comes
from `./Scripts/install.sh`.

## Update After Pulling Changes

Run the installer again:

```sh
./Scripts/install.sh
```

It rebuilds the app, replaces `~/Applications/GlassReminders.app`, rewrites the
LaunchAgent, and restarts the running menu-bar process.

## Stop Or Uninstall

Stop the running LaunchAgent:

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.pocketfm.glass-reminders.plist"
```

Remove installed app files:

```sh
rm -rf "$HOME/Applications/GlassReminders.app"
rm -f "$HOME/Library/LaunchAgents/com.pocketfm.glass-reminders.plist"
```

Optional: remove local reminder config and state:

```sh
rm -rf "$HOME/Library/Application Support/GlassReminders"
```
