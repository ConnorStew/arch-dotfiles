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
- `mako/` → `~/.config/mako/`
- `ssh/` → `~/.ssh/config`
- `sddm/` → `/etc/sddm.conf.d/`, `/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop`, `/var/lib/sddm/.config/weston.ini`
  - Requires `sudo stow --target=/ sddm`
  - Requires ACLs so the `sddm` user can read symlink targets — see README step 4
- `xone/` → `/etc/modprobe.d/xone.conf`
  - Requires `sudo stow --target=/ xone`
  - Blacklists `mt76x2u` so the Xbox wireless adapter is claimed by `xone-dongle` instead
- `reflector/` — NOT stowed. The reflector systemd service uses `ProtectHome=true` which blocks symlinks into `/home`. Config is tracked in the repo for version control but deployed as a plain copy (see README).
- `claude/` → `~/.config/systemd/user/claude-remote-control.service`
  - Runs `claude remote-control` for phone access via the Claude mobile app
  - Manual start only (no [Install] section): `systemctl --user start claude-remote-control`
  - Stop with: `systemctl --user stop claude-remote-control`
- `discord-update/` → `/etc/systemd/system/discord-update.{service,timer}`
  - Requires `sudo stow --target=/ discord-update`
  - Runs `pacman -Sy discord` 30s after boot
  - Enable with: `sudo systemctl enable --now discord-update.timer`
- `mimeapps/` → `~/.config/mimeapps.list`
  - Points MIME associations at the real installed `.desktop` IDs (e.g. `okularApplication_pdf.desktop`, `imv.desktop`, `org.kde.haruna.desktop`)
  - Dolphin's "Open With" dialog has a KF6/Plasma 6 bug (kio/kservice 6.27.0) where choosing an app — even from its suggestion list — doesn't match it to the existing service and instead fabricates a new throwaway `~/.local/share/applications/<name>-N.desktop` (`NoDisplay=true`) each time, so associations never appear to "stick". Set/change associations by editing this file directly instead of using Dolphin's dialog
- `alsa/` → `~/.asoundrc`
  - Forces ALSA's default PCM to `type pipewire`, overriding `alsa-plugins`' `99-pulseaudio-default.conf` which otherwise wins the `pipewire-pulse` vs `alsa-plugins` default-device race (see `workarounds/voice-mode-alsa-dsnoop.md`)

## Flatpak Notes

- VSCode terminal runs inside the Flatpak sandbox and can't see host binaries (`pacman`, `flatpak`, etc.)
  - Fixed via `flatpak-spawn --host` in `~/.var/app/com.visualstudio.code/config/Code/User/settings.json`
  - This file is **not stowed** (lives under `~/.var/app/`)
- GTK native dialogs (e.g. file pickers, sync confirmations) default to light theme in Flatpak apps
  - Fixed per-app with: `flatpak override --user --env=GTK_THEME=Adwaita:dark <app-id>`
  - Applied to: `com.visualstudio.code`, `com.brave.Browser`, `com.spotify.Client`

## Package Lists (`packages/`)

- `pkglist.txt` — native packages
- `pkglist-aur.txt` — AUR packages
- `dump.sh` — regenerates both lists
- See `README.md` for full restore instructions
