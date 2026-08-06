# MacTools

A single macOS menu-bar app combining four previously separate utilities:
live CPU/MEM monitoring, a Calculator/Calendar widget, clipboard history
with a global paste picker, and on-device screenshot OCR. Swift/AppKit + SwiftUI, no third-party
dependencies.

Supersedes four predecessor apps (each left intact, still independently buildable):
- [sysmonitor-menubar](https://github.com/soodrajesh/sysmonitor-menubar) — CPU/MEM readout, Free Up Memory
- `quick-tools` in [mac-widgets](https://github.com/soodrajesh/mac-widgets) — Calculator/Calendar popover
- [mac-clipboard](https://github.com/soodrajesh/mac-clipboard) / ClipKeep — clipboard history, ⌘⇧V picker
- [mac-ocr](https://github.com/soodrajesh/mac-ocr) / SnapText — screenshot-to-text via Vision, ⌘⇧O

## Features

- **Menu bar**: live two-line `CPU %` / `MEM %` readout (ported from mac-monitor), values turn red under load
- **Left-click** the icon → popover with 5 icon-tab switcher:
  - 🖥 **Stats** — CPU/Memory detail, top process, live network throughput (down/up) and disk I/O (read/write) with free/total capacity, Free Up Memory (runs `purge` immediately, no prompt — see setup below)
  - 📅 **Calendar** — month grid, Irish public holidays marked (computed algorithmically)
  - 🧮 **Calculator** — basic 4-op calculator
  - 📋 **Clipboard** — recent copies with real thumbnails for images, click to copy + auto-paste
  - 🔍 **OCR** — extract text from screenshots or existing images via on-device Vision framework
- **Right-click** the icon → Free Up Memory, Enable Accessibility (if not granted), Quit
- **⌘⇧V** anywhere → floating searchable paste-picker (independent of the popover), ↑/↓ to navigate, Return to paste
- **⌘⇧O** anywhere → macOS screenshot UI (same as ⌘⇧4), runs OCR, copies text to clipboard
- No Dock icon (`LSUIElement`); installs to `/Applications`, signed with a stable local identity so permission grants survive rebuilds

## Build

Requires the Xcode Command Line Tools (`xcode-select --install`).

```bash
./setup-signing.sh   # one-time: creates a local code-signing identity
./build.sh
```

Compiles `Sources/*.swift`, renders the app icon, signs, and installs to `/Applications/MacTools.app`.

**Why `setup-signing.sh`:** ad-hoc signing (`codesign --sign -`) embeds no identity —
just a hash of the raw binary — so every rebuild produces a different signature,
and macOS silently drops any Accessibility/Screen Recording grant keyed to it,
reprompting on next use. `setup-signing.sh` creates a self-signed local
certificate once; `build.sh` then signs with that stable identity instead, so
grants persist across rebuilds. If you skip this step, `build.sh` falls back to
ad-hoc signing and warns you.

## Before first launch

Quit the four predecessor apps if they're running, to avoid duplicate
clipboard polling and hotkey conflicts on ⌘⇧V and ⌘⇧O:

```bash
pkill -f SysMonitor; pkill -f QuickTools; pkill -f ClipKeep; pkill -f SnapText
```

```bash
open /Applications/MacTools.app
```

## Enable auto-paste & OCR (optional)

**Accessibility** (for clipboard auto-paste): MacTools prompts on first
launch. **This is a new bundle identity, so if you'd previously granted this
to ClipKeep, it does not carry over — grant it again:**

**System Settings → Privacy & Security → Accessibility → enable MacTools**

Without it, selecting a clipboard item still copies it — you just press ⌘V yourself.

**Screen Recording** (for OCR capture): MacTools prompts the first time you use
⌘⇧O or click "Capture Region" in the OCR tab. Grant it in:

**System Settings → Privacy & Security → Screen Recording → enable MacTools**

Without it, screenshot capture (and thus OCR) will fail silently.

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
