# Dotfiles Repo Memory

Arch Linux + Hyprland setup. All packages symlinked via stow.

## Stow Packages

- `bash/` → `~/.bashrc`, `~/.bash_profile`
- `hypr/` → `~/.config/hypr/`
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/` → `~/.config/wofi/`
- `sddm/` → `/etc/sddm.conf.d/`, `/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop`, `/var/lib/sddm/.config/weston.ini`
  - Requires `sudo stow --target=/ sddm`
  - Requires ACLs so the `sddm` user can read symlink targets — see README step 4
- `xone/` → `/etc/modprobe.d/xone.conf`
  - Requires `sudo stow --target=/ xone`
  - Blacklists `mt76x2u` so the Xbox wireless adapter is claimed by `xone-dongle` instead

## Package Lists (`packages/`)

- `pkglist.txt` — native packages
- `pkglist-aur.txt` — AUR packages
- `dump.sh` — regenerates both lists
- See `README.md` for full restore instructions
