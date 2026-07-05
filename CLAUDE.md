# Dotfiles Repo Memory

Arch Linux + Hyprland setup. All packages symlinked via stow.

## General Principles

All config files should be symlinked via stow. When adding or editing any config file, check whether it belongs in an existing stow package or needs a new one created.

## Stow Packages

- `bash/` → `~/.bashrc`, `~/.bash_profile`
- `hypr/` → `~/.config/hypr/`, `~/.config/systemd/user/wallpaper-cycle.{service,timer}`
  - Wallpapers cycle randomly from `~/wallpapers/` via `wallpaper-cycle.sh`, using `awww` (`awww-daemon` + `awww img`) — NOT `swww`. Arch's `swww` package was replaced by `awww` (same author, `Provides`/`Replaces: swww`, but a different CLI — `swww-daemon`/`swww img` don't exist under `awww`). We moved off `hyprpaper` entirely because `hyprctl hyprpaper preload`/`wallpaper` started failing with `invalid hyprpaper request` on hyprpaper 0.8.4 (a rewrite now linked against `hyprtoolkit`) paired with Hyprland 0.55.4 — a wire-protocol mismatch confirmed by raw-socket testing, not a config bug
  - `hyprland.conf` starts `awww-daemon` then immediately runs `wallpaper-cycle.sh` once via `exec-once` — required, not just for variety: `awww-daemon` starts with no wallpaper at all until something calls `awww img`, so skipping this would leave a blank screen until the timer's first fire
  - `wallpaper-cycle.timer` (systemd --user) re-runs the script every 30 min after that; `SUPER SHIFT W` also runs it manually (bound in `hyprland.conf`)
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/` → `~/.config/wofi/`
  - `colors` is wofi's own palette file (newline-separated hex values), referenced from `config` via `color=.config/wofi/colors`. It is NOT a pywal cache despite the filename — it was left empty from the initial commit, which is why wofi rendered with the plain light GTK theme instead of the rest of the rice
  - Palette: line0 `#1e2128` bg, line1 `#ffffff` text, line2 `#005a78` selected-entry accent, line3 `#595959` inactive border — matches mako's bg/border and hyprland's border colors
  - Reference them in `style.css` as `--wofi-color<n>` (n = line number − 1), e.g. `background-color: --wofi-color0;` — this is a literal text substitution done by wofi, not a CSS custom property/`var()`
  - `gtk_dark=true` is also set in `config` so native widget chrome (scrollbars etc.) not covered by the custom CSS still uses the dark GTK variant
- `mako/` → `~/.config/mako/`
- `ssh/` → `~/.ssh/config`
- `sddm/` → `/etc/sddm.conf.d/`, `/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop`, `/var/lib/sddm/.config/weston.ini`
  - Requires `sudo stow --target=/ sddm`
  - Requires ACLs so the `sddm` user can read symlink targets — see README step 4
- `xone/` → `/etc/modprobe.d/xone.conf`
  - Requires `sudo stow --target=/ xone`
  - Blacklists `mt76x2u` so the Xbox wireless adapter is claimed by `xone-dongle` instead
- `reflector/` — NOT stowed. The reflector systemd service uses `ProtectHome=true` which blocks symlinks into `/home`. Config is tracked in the repo for version control but deployed as a plain copy (see README).
- `xdg-terminals/` → `~/.config/xdg-terminals.list`
  - Tells `xdg-terminal-exec` (AUR) to prefer `kitty.desktop` when launching any `.desktop` entry with `Terminal=true`
  - Modern GLib (2.88+) no longer honors the old `/usr/bin/x-terminal-emulator` alternative convention for this — it checks `xdg-terminal-exec` first, then a hardcoded terminal list that doesn't include kitty. See `workarounds/nordvpn-xdg-open-terminal.md` (root cause was NordVPN's `nordvpn://` URL scheme handler silently failing to launch).
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
- `xdg-desktop-portal/` → `~/.config/xdg-desktop-portal/portals.conf`, `~/.config/gtk-3.0/settings.ini`
  - `portals.conf` routes `org.freedesktop.impl.portal.FileChooser`/`Settings` to the `gtk` backend. Without it, sandboxed apps (e.g. Flatpak Brave) can't open any file dialog under Hyprland: `xdg-desktop-portal-gtk`'s own `.portal` file restricts itself to `UseIn=gnome`, and `xdg-desktop-portal-hyprland` doesn't implement `FileChooser` at all, so with `XDG_CURRENT_DESKTOP=Hyprland` and no `portals.conf` the request has no backend to route to
    - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland`
  - `gtk-3.0/settings.ini` sets `gtk-application-prefer-dark-theme=true`, which is what actually makes those portal dialogs (`xdg-desktop-portal-gtk` is GTK3) render dark. `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` alone does NOT do this — confirmed by screenshotting a live portal `FileChooser.OpenFile` dialog, which stayed light with only `color-scheme` set and only turned dark once this file existed. Setting `gtk-theme` to a fake `'Adwaita-dark'` name doesn't work either — no such theme is installed under `/usr/share/themes`, so GTK3 silently falls back to plain light `Adwaita`
    - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal-gtk`

## Flatpak Notes

- VSCode terminal runs inside the Flatpak sandbox and can't see host binaries (`pacman`, `flatpak`, etc.)
  - Fixed via `flatpak-spawn --host` in `~/.var/app/com.visualstudio.code/config/Code/User/settings.json`
  - This file is **not stowed** (lives under `~/.var/app/`)
- GTK native dialogs *rendered inside the sandbox* (e.g. in-app sync confirmations) default to light theme in Flatpak apps
  - Fixed per-app with: `flatpak override --user --env=GTK_THEME=Adwaita:dark <app-id>`
  - Applied to: `com.visualstudio.code`, `com.brave.Browser`, `com.spotify.Client`
- File pickers (e.g. VS Code's "Open Folder") are NOT rendered by the sandboxed app — they're drawn by `xdg-desktop-portal-gtk`, a host-side process (`systemctl --user status xdg-desktop-portal-gtk`) that ignores the flatpak's `GTK_THEME` override entirely and instead reads the host's GTK3 config
  - Fixed system-wide (affects portal dialogs for all apps, not just Flatpak ones) — see `gtk-3.0/settings.ini` under the `xdg-desktop-portal/` stow package above
  - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal-gtk.service`

## Package Lists (`packages/`)

- `pkglist.txt` — native packages
- `pkglist-aur.txt` — AUR packages
- `dump.sh` — regenerates both lists
- See `README.md` for full restore instructions
