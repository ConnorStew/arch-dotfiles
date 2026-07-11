# Arch Dotfiles & System Config

My personal [Arch Linux](https://archlinux.org/) + [Hyprland](https://hyprland.org/)
setup — the whole machine, reproducible and version-controlled. Not just `$HOME`
dotfiles: package lists, root-owned system files, and service enables are managed
too, so a fresh install can be brought back to a fully-configured desktop from
this repo.

Configured for two hosts: `archlaptop` (Intel laptop) and `ArchPC` (NVIDIA
desktop).

## The two layers

The repo is split by *who owns the file*, because the two halves want completely
different tooling:

| Layer | What it manages | How |
|-------|-----------------|-----|
| **`dotfiles/`** | `$HOME` config (`~/.config/...`, `~/.bashrc`, ...) | live-symlinked with [GNU Stow](https://www.gnu.org/software/stow/) |
| **`system/`** | root files, package installs, service enables, per-host tweaks | a local [Ansible](https://www.ansible.com/) playbook |

**Why split them?** Stow is perfect for `$HOME` — symlink a package, edit the
file in place, and the change is already in the repo. But it's the wrong tool for
root-owned files (`sudo stow --target=/` symlinks system paths *back into* your
repo, and things like `ProtectHome` services then can't read them). So anything
outside `$HOME` — `/etc` files, `pacman`/AUR/Flatpak packages, `systemctl`
enables, ssh permissions — is deployed by Ansible as root-owned **copies**
instead, with per-host variables for the laptop and the desktop.

## The stack

- **Compositor** — Hyprland, with [hypridle](https://github.com/hyprwm/hypridle) + [hyprlock](https://github.com/hyprwm/hyprlock) for idle/lock
- **Bar** — [Waybar](https://github.com/Alexays/Waybar)
- **Launcher** — [wofi](https://hg.sr.ht/~scoopta/wofi)
- **Notifications** — [mako](https://github.com/emersion/mako)
- **Terminal** — [kitty](https://sw.kovidgoyal.org/kitty/)
- **Display manager** — [SDDM](https://github.com/sddm/sddm) with the [astronaut theme](https://github.com/keyitdev/sddm-astronaut-theme), colour-matched to hyprlock
- **Wallpapers** — [awww](https://github.com/LGFae/awww) with a script that cycles a random new one every 30 min
- **Audio** — PipeWire

## Repo layout

```
dotfiles/          # stow packages — one dir per app, targets $HOME
  hypr/ waybar/ wofi/ mako/ kitty/ bash/ ssh/ ...
system/            # Ansible playbook for everything root-owned
  group_vars/      # package lists (source of truth) + shared config
  host_vars/       # per-machine overrides (laptop vs. desktop)
  tasks/           # sddm, packages, reflector, wallpaper timers, ...
scripts/           # personal utility scripts (not stowed)
notes/             # how-to docs — see below
workarounds/       # documented fixes for hardware/driver quirks
```

## Getting started

The full walkthrough for bringing up a fresh machine — bootstrap yay, install the
playbook tooling, stow the dotfiles, set up host vars, run Ansible — lives in
[**notes/restoring-new-machine.md**](notes/restoring-new-machine.md).

The short version, once the repo is cloned:

```bash
# 1. Dotfiles — stow every package ($HOME symlinks)
cd ~/git/arch-dotfiles
stow $(ls dotfiles)

# 2. System — preview, then apply the Ansible layer
cd system
ansible-galaxy collection install -r requirements.yml   # once
ansible-playbook site.yml --limit "$(uname -n)" --check --diff -K   # dry run
ansible-playbook site.yml --limit "$(uname -n)" -K                  # apply
```

`.stowrc` sets `--dir=dotfiles` and points `--target` at the home directory, so
stow runs bare from the repo root with just package names. `--limit "$(uname -n)"`
scopes Ansible to the current host.

## Notes & workarounds

The [`notes/`](notes/) and [`workarounds/`](workarounds/) directories are my own
operational docs — new-machine bring-up, update routines, and fixes for various
hardware/driver quirks.

