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

## Stow (dotfiles)

`.stowrc` supplies `--dir`/`--target`, so no flags are needed:

```bash
cd ~/git/arch-config
stow hypr            # (re)stow a package
stow -D hypr         # unstow
stow -n hypr -v      # simulate
```

Stow or unstow **all** packages at once (`ls dotfiles` supplies the package names, since `.stowrc` already sets `--dir=dotfiles`):

```bash
cd ~/git/arch-config
stow $(ls dotfiles)      # stow every package
stow -D $(ls dotfiles)   # unstow every package
stow -R $(ls dotfiles)   # restow (unstow + stow) every package
```

Removing a file from a package:

1. Delete it from `dotfiles/<pkg>/…`
2. Remove the dangling symlink from `$HOME`
3. Restow to verify it's clean (`stow hypr`)

> Root-level config (SDDM, xone, discord-update, reflector) is **not** stow anymore — it's deployed by the Ansible playbook as root-owned copies. Don't `stow --target=/` anything; that recreates the symlink-into-repo problems this layout removed.

## Kitty Theme

Browse and set themes interactively:

```bash
kitty +kitten themes
```

Set a specific theme non-interactively:

```bash
kitty +kitten themes --reload-in=all "Cherry"
```

`current-theme.conf` is symlinked via stow, so theme changes are automatically reflected in the repo.

## Workarounds

See [`workarounds/`](workarounds/) for documented fixes to hardware/driver issues.

- [Xbox Wireless Adapter](workarounds/xbox-wireless-adapter.md) — blacklists `mt76x2u` which incorrectly claims the dongle
- [NordVPN xdg-open Terminal](workarounds/nordvpn-xdg-open-terminal.md) — browser login doesn't reach the app because `nordvpn.desktop` needs a terminal via `xdg-terminal-exec`
- [Brave blurry bookmarks bar](workarounds/brave-blurry-bookmarks-bar.md)
- [Voice-mode ALSA dsnoop](workarounds/voice-mode-alsa-dsnoop.md)

## Package drift

Package vars in `system/group_vars/all.yml` and `system/host_vars/<hostname>.yml` are the source of truth. To see what's installed but not declared (or vice versa):

```bash
system/scripts/check-drift.py
```

It diffs native (`pacman -Qenq`), AUR (`pacman -Qemq`), flatpak, and npm globals against the vars, ignoring the Arch install-time baseline and `*-debug` packages. When you install something new and want to keep it, add it to the appropriate var (`packages_common`/`packages_host`, `aur_packages`/`aur_host`, `flatpak_apps`, `npm_globals`) and re-run to confirm it's in sync.

## Full System Update

### 1. Snapshot with Timeshift

Always take a snapshot before a full update, especially if the kernel, NVIDIA, or GCC is involved:

```bash
sudo timeshift --create --comments "Before full system update"
```

Delete it once the system is confirmed stable after reboot.

### 2. Update native packages

```bash
sudo pacman -Syu
```

### 3. Check and update AUR packages

Before updating, review the PKGBUILDs for anything suspicious — especially check that sources download from expected upstream URLs with matching checksums:

```bash
yay -Syu
```

yay will show diffs for changed PKGBUILDs. Review before confirming.

### 4. Update Flatpak apps

```bash
flatpak update
```

### 5. Update npm globals

```bash
sudo npm update -g --allow-scripts=@anthropic-ai/claude-code
```

### 6. Reconcile the package vars

If the update added or removed anything you want tracked, edit the vars and confirm with:

```bash
system/scripts/check-drift.py
```

### Notes

- When updating kernel + NVIDIA + `xone-dkms`, always update all three together and reboot immediately after.
- Reboot after any update that includes `libdrm`, `mesa`, `nvidia`, or the kernel — these touch the GPU/display stack and need a clean reload.
- For hardware failure protection, use rclone to back up to Google Drive (see `scripts/sync-notes.sh`).

## Restoring on a new machine

Start from a standard Arch **base** install (via `archinstall` or manual `pacstrap base linux …`). That already provides the baseline packages (`base`, `linux`, `grub`, `sudo`, `networkmanager`, …) that the playbook deliberately doesn't manage.

### 1. Clone the repo

```bash
sudo pacman -S --needed git
git clone git@github.com:ConnorStew/arch-config.git ~/git/arch-config
```

### 2. Bootstrap yay (AUR helper)

`makepkg` refuses to run as root, so yay is a one-time manual bootstrap:

```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

### 3. Install the tools to run the playbook

```bash
sudo pacman -S --needed ansible stow
ansible-galaxy collection install -r ~/git/arch-config/system/requirements.yml
```

### 4. Stow the dotfiles

```bash
cd ~/git/arch-config
stow alsa bash hypr kitty mako mimeapps ssh waybar wofi xdg-desktop-portal xdg-terminals
```

### 5. Set up host vars (desktop only)

`archlaptop` already has `system/host_vars/archlaptop.yml`. On a new machine whose hostname isn't yet known to the playbook:

1. `cp system/host_vars/desktop.yml.example system/host_vars/$(uname -n).yml` and fill it in (nvidia set, `xone_enabled`, `sddm_greeter_weston`, etc.).
2. Add that hostname to `system/inventory.yml`.

### 6. Run the playbook

```bash
cd system
ansible-playbook site.yml --limit "$(uname -n)" --check --diff -K   # preview
ansible-playbook site.yml --limit "$(uname -n)" -K                  # apply
```

This installs native packages, enables SDDM/reflector/discord-update, sets ssh perms, deploys and enables the user units, installs flatpaks, and applies everything else. Multilib (for Steam) is enabled by the playbook — no manual `pacman.conf` edit needed.

### 7. Install AUR packages manually

AUR packages are **not** installed by the playbook — it only lists the missing ones so you can review each PKGBUILD first (see the `Report AUR packages needing manual installation` task output). Install them by hand:

```bash
yay -S <pkg> …
```

Then re-run `system/scripts/check-drift.py` to confirm nothing's left declared-but-missing.
