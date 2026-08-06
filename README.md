# MacTools

A single macOS menu-bar app combining three previously separate utilities:
live CPU/MEM monitoring, a Calculator/Calendar widget, and clipboard history
with a global paste picker. Swift/AppKit + SwiftUI, no third-party
dependencies.

Supersedes three predecessor apps (each left intact, still independently buildable):
- [sysmonitor-menubar](https://github.com/soodrajesh/sysmonitor-menubar) — CPU/MEM readout, Free Up Memory
- `quick-tools` in [mac-widgets](https://github.com/soodrajesh/mac-widgets) — Calculator/Calendar popover
- [mac-clipboard](https://github.com/soodrajesh/mac-clipboard) / ClipKeep — clipboard history, ⌘⇧V picker

## Features

- **Menu bar**: live two-line `CPU %` / `MEM %` readout (ported from mac-monitor), values turn red under load
- **Left-click** the icon → popover with 4 icon-tab switcher:
  - 🖥 **Stats** — CPU/Memory detail, top process, live network throughput (down/up) and disk I/O (read/write) with free/total capacity, Free Up Memory (runs `purge` immediately, no prompt — see setup below)
  - 📅 **Calendar** — month grid, Irish public holidays marked (computed algorithmically)
  - 🧮 **Calculator** — basic 4-op calculator
  - 📋 **Clipboard** — recent copies with real thumbnails for images, click to copy + auto-paste
- **Right-click** the icon → Free Up Memory, Enable Accessibility (if not granted), Quit
- **⌘⇧V** anywhere → floating searchable paste-picker (independent of the popover), ↑/↓ to navigate, Return to paste
- No Dock icon (`LSUIElement`); installs to `/Applications`, ad-hoc codesigned so the Accessibility grant survives rebuilds

## Build

Requires the Xcode Command Line Tools (`xcode-select --install`).

```bash
./build.sh
```

Compiles `Sources/*.swift`, renders the app icon, ad-hoc signs, and installs to `/Applications/MacTools.app`.

## Before first launch

Quit the three predecessor apps if they're running, to avoid duplicate
clipboard polling and a hotkey conflict on ⌘⇧V:

```bash
pkill -f SysMonitor; pkill -f QuickTools; pkill -f ClipKeep
```

```bash
open /Applications/MacTools.app
```

## Enable auto-paste (optional)

Clipboard auto-paste needs Accessibility access — MacTools prompts on first
launch. **This is a new bundle identity, so if you'd previously granted this
to ClipKeep, it does not carry over — grant it again:**

**System Settings → Privacy & Security → Accessibility → enable MacTools**

Without it, selecting a clipboard item still copies it — you just press ⌘V yourself.

## Free Up Memory setup (optional)

`purge` needs root. Free Up Memory has no confirmation prompt — it runs
immediately via a narrow passwordless-sudo rule scoped to just this one
command:

```bash
echo "$(whoami) ALL=(root) NOPASSWD: /usr/sbin/purge" | \
  sudo tee /etc/sudoers.d/mactools-purge >/dev/null
sudo chmod 440 /etc/sudoers.d/mactools-purge
sudo visudo -c
```

Without this rule, Free Up Memory will fail (`sudo -n` doesn't prompt for a password — it just fails silently without the rule installed).

## Auto-start at login

System Settings → General → Login Items & Extensions → **+** → select `MacTools.app`.

## License

MIT
