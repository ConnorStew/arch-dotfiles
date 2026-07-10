# Dotfiles Repo Memory

Arch Linux + Hyprland setup. Two layers:

- **`dotfiles/`** — `$HOME` config, live-symlinked via stow. `.stowrc` sets
  `--dir=dotfiles --target=/home/connor`, so stow runs bare from the repo root
  with just package names (`stow hypr`, `stow -D hypr`, `stow $(ls dotfiles)`).
- **`system/`** — everything else (root-level files, service enables, package
  installs, ssh perms) as a local Ansible playbook, with per-host vars for
  `archlaptop` and the desktop.

## General Principles

`$HOME` config files should be symlinked via stow — when adding or editing one,
check whether it belongs in an existing `dotfiles/` package or needs a new one.
Anything root-owned, a service enable, or a package install belongs in the
Ansible layer under `system/`, **not** stow (`sudo stow --target=/` is gone —
it caused symlink-into-repo problems that root-owned copies avoid).

## Stow Packages (`dotfiles/`, `$HOME` targets only)

- `bash/` → `~/.bashrc`, `~/.bash_profile`
- `hypr/` → `~/.config/hypr/`
  - Wallpapers cycle randomly from `~/wallpapers/` via `wallpaper-cycle.sh`, using `awww` (`awww-daemon` + `awww img`) — NOT `swww`. Arch's `swww` package was replaced by `awww` (same author, `Provides`/`Replaces: swww`, but a different CLI — `swww-daemon`/`swww img` don't exist under `awww`). We moved off `hyprpaper` entirely because `hyprctl hyprpaper preload`/`wallpaper` started failing with `invalid hyprpaper request` on hyprpaper 0.8.4 (a rewrite now linked against `hyprtoolkit`) paired with Hyprland 0.55.4 — a wire-protocol mismatch confirmed by raw-socket testing, not a config bug
  - `wallpaper-cycle.sh` excludes the currently-displayed image from the random pick (via `awww query`) so a re-roll always visibly changes the wallpaper, falling back to the full list only if that would empty the pool (e.g. a single-wallpaper folder)
  - `awww-daemon` restores the last-displayed wallpaper per output from its own cache on startup by default (see `awww-daemon --help`, `--no-cache` disables this) — so `hyprland.conf` does NOT run `wallpaper-cycle.sh` on login, since that would always force a fresh random pick and fight the cache restore. Instead it runs `wallpaper-init.sh` once via `exec-once` (after a `sleep 1` so the daemon's socket exists), which only sets a wallpaper (instant, `--transition-type none`) if `awww query` shows none is displayed yet — i.e. first-ever run with an empty cache. On every subsequent login the cache restore already has it covered and the init script is a no-op
  - `wallpaper-cycle.timer` (systemd --user) runs `wallpaper-cycle.sh` every 30 min for the actual periodic cycling; `SUPER SHIFT W` also runs it manually (bound in `hyprland.conf`). The `wallpaper-cycle.{service,timer}` unit files are deployed **and** enabled by Ansible (`tasks/user-config.yml`, from `system/files/wallpaper-cycle/`) — they are NOT stowed. The script they run (`wallpaper-cycle.sh`) still lives in this stow package
  - Screen locking: `hypridle` is autostarted via `hyprland.conf` (`exec-once = hypridle`) — no separate service/timer to enable. Its `general` block locks the session (`loginctl lock-session`, which triggers `hyprlock` via `lock_cmd`) via `before_sleep_cmd`, so closing the lid (which triggers `HandleLidSwitch=suspend` in logind, left at its default in `/etc/systemd/logind.conf`) locks before the actual suspend; a `listener` block also locks after 10 min idle
  - `hyprlock.conf` is styled to match the installed `sddm-astronaut-theme` (see the System Layer section below) — same background image (`/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/jake_the_dog.png`), palette (`#242455` bg / `#d8d8ff` text / `#6c6caa` placeholder), and `Thunderman` font, referenced directly from the theme's installed path rather than duplicated into this repo
  - It also has Restart/Shut Down `label` widgets (bottom-right, using hyprlock's `onclick` support) that run `systemctl reboot` / `systemctl poweroff` directly, mirroring the SDDM theme's system buttons
- `waybar/` → `~/.config/waybar/`
- `kitty/` → `~/.config/kitty/`
- `wofi/` → `~/.config/wofi/`
  - `colors` is wofi's own palette file (newline-separated hex values), referenced from `config` via `color=.config/wofi/colors`. It is NOT a pywal cache despite the filename — it was left empty from the initial commit, which is why wofi rendered with the plain light GTK theme instead of the rest of the rice
  - Palette: line0 `#1e2128` bg, line1 `#ffffff` text, line2 `#005a78` selected-entry accent, line3 `#595959` inactive border — matches mako's bg/border and hyprland's border colors
  - Reference them in `style.css` as `--wofi-color<n>` (n = line number − 1), e.g. `background-color: --wofi-color0;` — this is a literal text substitution done by wofi, not a CSS custom property/`var()`
  - `gtk_dark=true` is also set in `config` so native widget chrome (scrollbars etc.) not covered by the custom CSS still uses the dark GTK variant
- `mako/` → `~/.config/mako/`
- `ssh/` → `~/.ssh/config`
  - Permissions (`~/.ssh` 0700, `~/.ssh/config` 0600) are enforced by Ansible (`tasks/user-config.yml`), not a manual `chmod` — ssh refuses configs with loose perms
- `xdg-terminals/` → `~/.config/xdg-terminals.list`
  - Tells `xdg-terminal-exec` (AUR) to prefer `kitty.desktop` when launching any `.desktop` entry with `Terminal=true`
  - Modern GLib (2.88+) no longer honors the old `/usr/bin/x-terminal-emulator` alternative convention for this — it checks `xdg-terminal-exec` first, then a hardcoded terminal list that doesn't include kitty. See `workarounds/nordvpn-xdg-open-terminal.md` (root cause was NordVPN's `nordvpn://` URL scheme handler silently failing to launch).
- `mimeapps/` → `~/.config/mimeapps.list`
  - Points MIME associations at the real installed `.desktop` IDs (e.g. `okularApplication_pdf.desktop`, `imv.desktop`, `org.kde.haruna.desktop`)
  - Dolphin's "Open With" dialog has a KF6/Plasma 6 bug (kio/kservice 6.27.0) where choosing an app — even from its suggestion list — doesn't match it to the existing service and instead fabricates a new throwaway `~/.local/share/applications/<name>-N.desktop` (`NoDisplay=true`) each time, so associations never appear to "stick". Set/change associations by editing this file directly instead of using Dolphin's dialog
- `discord/` → `~/.local/share/applications/discord.desktop`
  - A user-level override of the packaged `/usr/share/applications/discord.desktop` (which `~/.local/share/applications` shadows via XDG data-dir precedence). It only adds `--enable-features=UseOzonePlatform --ozone-platform=wayland` to the `Exec` line so Discord (Electron/Chromium) draws a native Wayland surface instead of running under XWayland — XWayland-hosted Electron renders fuzzy/soft even at integer `scale 1`. Kept as a stow package rather than editing the system file because that file is root-owned and the `discord-update` timer runs `pacman -Sy discord` on every boot, which would clobber it. Run `update-desktop-database ~/.local/share/applications` after changing it. See `workarounds/discord-fuzzy-xwayland.md`
- `alsa/` → `~/.asoundrc`
  - Forces ALSA's default PCM to `type pipewire`, overriding `alsa-plugins`' `99-pulseaudio-default.conf` which otherwise wins the `pipewire-pulse` vs `alsa-plugins` default-device race (see `workarounds/voice-mode-alsa-dsnoop.md`)
- `xdg-desktop-portal/` → `~/.config/xdg-desktop-portal/portals.conf`, `~/.config/gtk-3.0/settings.ini`
  - `portals.conf` routes `org.freedesktop.impl.portal.FileChooser`/`Settings` to the `gtk` backend. Without it, sandboxed apps (e.g. Flatpak Brave) can't open any file dialog under Hyprland: `xdg-desktop-portal-gtk`'s own `.portal` file restricts itself to `UseIn=gnome`, and `xdg-desktop-portal-hyprland` doesn't implement `FileChooser` at all, so with `XDG_CURRENT_DESKTOP=Hyprland` and no `portals.conf` the request has no backend to route to
    - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland`
  - `gtk-3.0/settings.ini` sets `gtk-application-prefer-dark-theme=true`, which is what actually makes those portal dialogs (`xdg-desktop-portal-gtk` is GTK3) render dark. `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` alone does NOT do this — confirmed by screenshotting a live portal `FileChooser.OpenFile` dialog, which stayed light with only `color-scheme` set and only turned dark once this file existed. Setting `gtk-theme` to a fake `'Adwaita-dark'` name doesn't work either — no such theme is installed under `/usr/share/themes`, so GTK3 silently falls back to plain light `Adwaita`
    - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal-gtk`

## System Layer (`system/`, Ansible)

Root files, service enables, ssh perms, and package installs. Run from `system/`:

```bash
ansible-galaxy collection install -r requirements.yml            # once (community.general, kewlfft.aur)
ansible-playbook site.yml --limit "$(uname -n)" --check --diff -K  # preview
ansible-playbook site.yml --limit "$(uname -n)" -K                 # apply
```

`inventory.yml` has one entry per machine (`inventory_hostname` == real hostname,
so `host_vars/<hostname>.yml` auto-loads); always scope with `--limit "$(uname -n)"`.
Runs as `connor`; individual tasks opt into `become: true`. `systemctl --user`
enables use `scope: user` (no become). All root files are **copies** with
`follow: false` (a leftover stow symlink is replaced, never written through into
the repo).

Task files (`system/tasks/`):

- `sddm.yml` — copies `theme.conf` → `/etc/sddm.conf.d/`, `metadata.desktop` → the installed theme dir, and (desktop only, gated on `sddm_greeter_weston`) `weston.ini` → `/var/lib/sddm/.config/`; root-owned 0644. Ensures `/etc/sddm.conf.d` exists first, because `copy` refuses to create a missing parent dir. Then enables `sddm.service` and sets `graphical.target`. No ACLs — root-owned copies don't need the `sddm` user to traverse `/home`.
- `xone.yml` — copies `xone.conf` → `/etc/modprobe.d/`, gated on `xone_enabled` (desktop only). Blacklists `mt76x2u` so the Xbox wireless adapter is claimed by `xone-dongle` instead.
- `discord-update.yml` — copies units → `/etc/systemd/system/` + enables the timer, gated on `discord_update_enabled` (default true). Runs `pacman -Sy discord` 30s after boot.
- `reflector.yml` — copies `reflector.conf` → `/etc/xdg/reflector/` + enables the timer. (Was always a copy, never stow: the reflector service uses `ProtectHome=true`, which blocks symlinks into `/home`.)
- `claude-remote-control.yml` — gated on `claude_remote_control_enabled` (default false — opt in per host); when enabled it copies `claude-remote-control.service` → `~/.config/systemd/user/` and enables + starts it. Runs `claude remote-control` for phone access via the Claude mobile app. `claude` is npm-managed (`@anthropic-ai/claude-code`), NOT AUR.
- `user-config.yml` — ssh perms (see `ssh/` above); deploys the `wallpaper-cycle.{service,timer}` user units (from `system/files/wallpaper-cycle/`) into `~/.config/systemd/user/`; and enables the user timers/services `arch-update.timer`, `arch-update-tray.service`, `wallpaper-cycle.timer`.
- `packages.yml` — see Packages below.

## Packages (Ansible vars)

Package lists live in `system/group_vars/all.yml` (`packages_common`,
`aur_packages`, `flatpak_apps`, `flatpak_gtk_dark`, `npm_globals`) and
`system/host_vars/<hostname>.yml` (`packages_host`, `aur_host`). These vars are
the source of truth — the old `packages/` dir with `pkglist*.txt` and `dump.sh`
is gone.

- **Native** (`packages.yml` → `community.general.pacman`): `packages_common + packages_host`. Multilib is enabled by the playbook (for Steam) via a `replace` on `/etc/pacman.conf`. The Arch install-time baseline (`base`, `linux`, `grub`, `sudo`, `networkmanager`, …) is deliberately NOT declared — a fresh install already has it.
- **AUR** is **always installed manually** with `yay -S <pkg>` so the PKGBUILD can be reviewed. The playbook only *lists* the declared-but-missing ones (`Report AUR packages needing manual installation` task) — it never builds anything. `yay` itself is a one-time git-clone bootstrap (makepkg refuses to run as root).
- **Flatpak**: `flatpak_apps` installed `--system` from Flathub. `flatpak_gtk_dark` apps get a `GTK_THEME=Adwaita:dark` `--user` override (currently Brave + Spotify; see Flatpak Notes).
- **npm globals**: `npm_globals` (just `@anthropic-ai/claude-code`).

`system/scripts/check-drift.py` diffs the vars against what's actually installed
(native `pacman -Qenq`, AUR `pacman -Qemq`, flatpak, npm globals) in both
directions, ignoring the Arch baseline and `*-debug` packages. Run it after
installing something new: add it to the right var, then confirm it's in sync.

## Flatpak Notes

- GTK native dialogs *rendered inside the sandbox* (e.g. in-app sync confirmations) default to light theme in Flatpak apps
  - Fixed per-app with `flatpak override --user --env=GTK_THEME=Adwaita:dark <app-id>`, now automated by `packages.yml` via the `flatpak_gtk_dark` var (applied to `com.brave.Browser`, `com.spotify.Client`)
  - VSCode is installed from the AUR (`visual-studio-code-bin`), not Flatpak, so it needs none of this (no sandbox, no `flatpak-spawn` shim, no override)
- File pickers (e.g. Brave's save-file dialog) are NOT rendered by the sandboxed app — they're drawn by `xdg-desktop-portal-gtk`, a host-side process (`systemctl --user status xdg-desktop-portal-gtk`) that ignores the flatpak's `GTK_THEME` override entirely and instead reads the host's GTK3 config
  - Fixed system-wide (affects portal dialogs for all apps, not just Flatpak ones) — see `gtk-3.0/settings.ini` under the `xdg-desktop-portal/` stow package above
  - Apply immediately without logout: `systemctl --user restart xdg-desktop-portal-gtk.service`
