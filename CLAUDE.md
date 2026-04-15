# Dotfiles Repo Memory

Arch Linux + Hyprland setup. All packages symlinked via stow.

## General Principles

All config files should be symlinked via stow. When adding or editing any config file, check whether it belongs in an existing stow package or needs a new one created.

## Stow Packages

- `bash/` → `~/.bashrc`, `~/.bash_profile`
- `hypr/` → `~/.config/hypr/`
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/` → `~/.config/wofi/`
- `ssh/` → `~/.ssh/config`
- `sddm/` → `/etc/sddm.conf.d/`, `/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop`, `/var/lib/sddm/.config/weston.ini`
  - Requires `sudo stow --target=/ sddm`
  - Requires ACLs so the `sddm` user can read symlink targets — see README step 4
- `xone/` → `/etc/modprobe.d/xone.conf`
  - Requires `sudo stow --target=/ xone`
  - Blacklists `mt76x2u` so the Xbox wireless adapter is claimed by `xone-dongle` instead
- `discord-update/` → `/etc/systemd/system/discord-update.{service,timer}`
  - Requires `sudo stow --target=/ discord-update`
  - Runs `pacman -Sy discord` 30s after boot
  - Enable with: `sudo systemctl enable --now discord-update.timer`

## Package Lists (`packages/`)

- `pkglist.txt` — native packages
- `pkglist-aur.txt` — AUR packages
- `dump.sh` — regenerates both lists
- See `README.md` for full restore instructions
