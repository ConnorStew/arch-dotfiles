# Arch Dotfiles & System Config

Two layers:

- **`dotfiles/`** — `$HOME` config, live-symlinked with [GNU stow](https://www.gnu.org/software/stow/). Edit in place; changes are reflected in the repo.
- **`system/`** — everything else (root-level files, service enables, package installs, ssh perms) as a local Ansible playbook, with per-host vars for `archlaptop` and the desktop.

`.stowrc` sets `--dir=dotfiles --target=/home/connor`, so every stow command runs bare from the repo root with just package names.

## Scripts (`scripts/`)

Personal utility scripts — not stowed, run manually.

| Script | Description |
|--------|-------------|
| `sync-notes.sh` | Bidirectional rclone sync for Obsidian notes and DnD folder to Google Drive. Does a dry run first with confirmation. Usage: `./scripts/sync-notes.sh [obsidian\|dnd\|both]` |

(System-management scripts live under `system/scripts/`, e.g. `check-drift.py` — see [Package drift](#package-drift).)


## Workarounds

See [`workarounds/`](workarounds/) for documented fixes to hardware/driver issues.

- [Xbox Wireless Adapter](workarounds/xbox-wireless-adapter.md) — blacklists `mt76x2u` which incorrectly claims the dongle
- [NordVPN xdg-open Terminal](workarounds/nordvpn-xdg-open-terminal.md) — browser login doesn't reach the app because `nordvpn.desktop` needs a terminal via `xdg-terminal-exec`
- [Brave blurry bookmarks bar](workarounds/brave-blurry-bookmarks-bar.md)
- [Voice-mode ALSA dsnoop](workarounds/voice-mode-alsa-dsnoop.md)

