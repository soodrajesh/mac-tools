# MacTools

A single macOS menu-bar app combining live system monitoring, quick widgets,
clipboard history with a global paste picker, and a scratch notepad. Swift/AppKit
+ SwiftUI, no third-party dependencies.

Supersedes three predecessor apps (each left intact, still independently buildable):

- [sysmonitor-menubar](https://github.com/soodrajesh/sysmonitor-menubar) — CPU/MEM readout, Free Up Memory
- `quick-tools` in [mac-widgets](https://github.com/soodrajesh/mac-widgets) — Calculator/Calendar popover
- [mac-clipboard](https://github.com/soodrajesh/mac-clipboard) / ClipKeep — clipboard history, ⌘⇧V picker

## Features

### Menu bar

- Live two-line **CPU %** / **MEM %** readout; values turn **red** under load
- **Left-click** → popover (five tabs, fixed size so switching tabs does not resize the panel)
- **Right-click** → Free Up Memory, Enable Accessibility (if needed), Quit
- No Dock icon (`LSUIElement`); installs to `/Applications`, ad-hoc signed so Accessibility survives rebuilds

### Popover tabs

| Tab | What it does |
|-----|----------------|
| **Stats** | CPU/memory detail, top CPU process, network and disk throughput, disk free/total, **Free Up Memory** |
| **Calendar** | Month grid; Irish public holidays (computed) |
| **Calculator** | Basic four-operation calculator |
| **Clipboard** | Recent copies (image thumbnails); click to copy and auto-paste into the app you had focused |
| **Notepad** | Scratch pad with debounced auto-save; **Copy** and **Clear** (with confirm) buttons |

### Global hotkeys

| Shortcut | Action |
|----------|--------|
| **⌘⇧V** | Floating searchable paste-picker (↑/↓, Return to paste) — works from any app |
| **⌘⇧N** | Open the popover on the **Notepad** tab (or switch to it if the popover is already open) |

### Notepad editing

Click inside the text area so it has focus, then use standard shortcuts:

| Shortcut | Action |
|----------|--------|
| **⌘A** | Select all |
| **⌘C** | Copy |
| **⌘X** | Cut |
| **⌘V** | Paste |
| **⌘Z** / **⌘⇧Z** | Undo / redo |

MacTools installs a hidden **Edit** menu so these work in a menu-bar-only app.

**Data file:** `~/Library/Application Support/MacTools/notepad.txt`

## Build

Requires the Xcode Command Line Tools (`xcode-select --install`).

```bash
./build.sh
```

Compiles `Sources/*.swift`, renders the app icon, ad-hoc signs, and installs to `/Applications/MacTools.app`.

## Before first launch

Quit predecessor apps to avoid duplicate clipboard polling and a **⌘⇧V** conflict:

```bash
pkill -f SysMonitor; pkill -f QuickTools; pkill -f ClipKeep
open /Applications/MacTools.app
```

## Enable auto-paste (optional)

Clipboard auto-paste needs **Accessibility**. MacTools uses a new bundle ID — a
grant to ClipKeep does **not** carry over.

**System Settings → Privacy & Security → Accessibility → enable MacTools**

Without it, picking from history still copies to the clipboard; you paste with **⌘V** in the target app yourself.

## Free Up Memory

`purge` requires root. **Free Up Memory** uses the system administrator sheet
(**Touch ID** where available, otherwise your password). That works on managed
Macs where custom `/etc/sudoers.d` files are blocked.

### Skip the prompt (optional)

If you can edit sudoers, a narrow **NOPASSWD** rule for `/usr/sbin/purge` only
lets MacTools run silently (it tries `sudo -n` first):

```bash
echo "$(whoami) ALL=(root) NOPASSWD: /usr/sbin/purge" | \
  sudo tee /etc/sudoers.d/mactools-purge >/dev/null
sudo chmod 440 /etc/sudoers.d/mactools-purge
sudo visudo -c
```

## Data on disk

| Path | Purpose |
|------|---------|
| `~/Library/Application Support/MacTools/notepad.txt` | Notepad text |
| `~/Library/Application Support/ClipKeep/` | Clipboard history (JSON + image PNGs; shared layout with ClipKeep) |

## Auto-start at login

**System Settings → General → Login Items & Extensions → +** → `MacTools.app`

## License

MIT
