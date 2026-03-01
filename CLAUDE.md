# Dotfiles Repo Memory

## Repo
- Arch Linux + Hyprland setup

## Stow Setup (COMPLETE)

All packages are symlinked via `stow --adopt`:
- `bash/` → `~/.bashrc`, `~/.bash_profile`
- `hypr/` → `~/.config/hypr/`
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/` → `~/.config/wofi/`

## Package Lists

Stored in `packages/`:
- `pkglist.txt` — native packages
- `pkglist-aur.txt` — AUR packages
- `dump.sh` — regenerates both lists
- `README.md` (repo root) — restore instructions for a new machine

## Repo Structure
```
arch-dotfiles/
  bash/
    .bashrc
    .bash_profile
  hypr/
    .config/hypr/
      hyprland.conf
      hyprpaper.conf
      wofi-cursor.sh
  waybar/
    .config/waybar/
      config
      power_menu.xml
      style.css
  kitty/
    .config/kitty/
      kitty.conf
  wofi/
    .config/wofi/
      colors
      config
      style.css
```

