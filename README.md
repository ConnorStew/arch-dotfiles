# Arch Dotfiles & System Config

My personal reproducible, version-controlled [Arch Linux](https://archlinux.org/) + [Hyprland](https://hyprland.org/) setup.

Used to manage package lists, services, and general config for both my laptop and my desktop computers.

I'd originally tried Nix to keep my desktop and laptop in sync. I disliked having to edit the config files for every change,
so I went with Arch + this repo to give me the freedom to make changes on the fly while keeping important config synced.

## The management tooling

The repo is split between dotfiles that can be updated on the fly and services or items requiring root.

| Tool | What it manages | Where |
|------|-----------------|-------|
| [GNU Stow](https://www.gnu.org/software/stow/)| `$HOME` config, symlinked into place | **`dotfiles/`** | 
| [Ansible](https://www.ansible.com/) | root files, package installs, service enables, per-host tweaks |  **`system/`** |

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
notes/             # how-to docs
workarounds/       # documented fixes for hardware/driver quirks
```

## Notes & workarounds

The [`notes/`](notes/) and [`workarounds/`](workarounds/) directories are my own
docs — new-machine bring-up, update routines, and fixes for various quirks.
