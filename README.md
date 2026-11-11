# Lock Top Bar

An [Omarchy](https://omarchy.org) status bar plugin (`omarchy-shell` / Quickshell) providing a lock icon toggle on the top bar.

When locked, it shields the top bar from unintended modifications caused by accidental clicks:
- **Prevents accidental transparency cycling**: blocks toggling bar background look (`opaque` / `glassy` / `none`) on bar double-click.
- **Prevents accidental workspace layout switching**: blocks cycling active workspace between dwindle, scrolling, and floating when clicking the active workspace number in the bar.
- **Prevents accidental bar dragging / repositioning**.
- **Desktop notifications**: displays an unobtrusive toast notification when an action is blocked while locked.
- **IPC Support**: control lock state via CLI or custom Hyprland keybindings.

> Marketplace ID: `io.github.culcat.lock-topbar`

## Features

- **Top Bar Icon Widget**:
  - `󰌾` **Locked** (accent color) — bar modifications blocked.
  - `󰌿` **Unlocked** (dimmed) — normal bar behavior.
- **Left click**: Instantly toggle lock state on/off.
- **Right click**: Open settings card with granular toggles:
  - *Lock Bar Background* (block double-click transparency change)
  - *Lock Workspace Layout* (block layout change on active workspace)
  - *Desktop Notifications* (notify when an action is blocked)
- **Persistent State**: Retains your lock preference and options across shell restarts.
- **Full Localization**: English and Russian support built-in.

## Installation

### Via Omarchy plugin manager:

```bash
omarchy plugin add https://github.com/culcat/LockTopBar.git --enable
```

### Manual installation:

```bash
git clone https://github.com/culcat/LockTopBar.git \
  ~/.config/omarchy/plugins/io.github.culcat.lock-topbar
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.culcat.lock-topbar
```

To position the widget on the top bar (e.g. right section):

```bash
omarchy bar move io.github.culcat.lock-topbar --section right
```

## Keybindings & IPC

You can bind lock toggling to a shortcut in `~/.config/hypr/bindings.lua`:

```lua
-- Toggle Top Bar Lock with Super + Alt + L
hl.bind({ "super", "alt" }, "l", "omarchy-shell io.github.culcat.lock-topbar toggle")
```

Available IPC commands:
```bash
omarchy-shell io.github.culcat.lock-topbar toggle
omarchy-shell io.github.culcat.lock-topbar lock
omarchy-shell io.github.culcat.lock-topbar unlock
omarchy-shell io.github.culcat.lock-topbar status
```

## Settings

Settings can also be configured inline in `~/.config/omarchy/shell.json`:

```json
{
  "id": "io.github.culcat.lock-topbar",
  "locked": true,
  "lockBackground": true,
  "lockLayout": true,
  "showNotifications": true
}
```

## License

MIT © culcat
