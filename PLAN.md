# Plan: Ansible for the System Layer

Goal: keep stow for `$HOME` dotfiles (live symlinks, edit-in-place), move everything
else — root-level files, service enables, package installs, and the README's manual
restore steps — into a small local Ansible playbook with per-host vars for
`archlaptop` and the desktop.

Wins this buys:

- No more `sudo stow --target=/` special cases — system files become root-owned
  **copies**, which is what reflector (ProtectHome) and SDDM (ACLs) already proved
  they want to be.
- The entire SDDM ACL section of the README disappears.
- Per-host divergence (packages, xone, monitors) gets a proper home in `host_vars/`
  instead of a shared list that `dump.sh` clobbers.
- `ansible-playbook --check --diff` becomes the drift detector the README can't be.

## Target layout

```
arch-config/
├── dotfiles/                  # stow packages, $HOME targets only
│   ├── bash/  hypr/  waybar/  kitty/  wofi/  mako/
│   ├── ssh/  mimeapps/  alsa/  claude/
│   ├── xdg-desktop-portal/  xdg-terminals/
├── system/
│   ├── ansible.cfg            # inventory path, defaults
│   ├── inventory.yml          # localhost, ansible_connection: local
│   ├── requirements.yml       # community.general, kewlfft.aur
│   ├── site.yml
│   ├── group_vars/all.yml     # shared packages, flatpaks, npm globals
│   ├── host_vars/
│   │   ├── archlaptop.yml
│   │   └── <desktop-hostname>.yml   # TODO: fill in real hostname
│   └── files/
│       ├── sddm/              # theme.conf, metadata.desktop, weston.ini, forest.jpg
│       ├── xone.conf
│       ├── discord-update.service / .timer
│       └── reflector.conf
├── packages/                  # deleted — folded into ansible vars (see Phase 4)
├── scripts/                   # unchanged (+ new check-drift.sh)
├── workarounds/               # unchanged
├── README.md                  # shrinks to: clone → stow → run playbook
└── .stowrc                    # --dir=dotfiles --target=/home/connor (see Phase 1)
```

## Phase 1 — Move stow packages under `dotfiles/`

The whole point: `.stowrc` becomes the single place that knows *where the packages
live* (`--dir`) and *where they land* (`--target`), so every `stow`/`stow -D`
command runs bare from the repo root with just package names — no `-d`/`-t` flags
to remember or get wrong.

1. **Unstow with the *old* `.stowrc` still in place** — stow needs `--dir`/`--target`
   to match how the links were originally made, or `-D` won't recognize (and remove)
   them:

   ```bash
   # from repo root, .stowrc still = --target=/home/connor (no --dir yet)
   stow -D bash hypr waybar kitty wofi mako ssh mimeapps alsa claude xdg-desktop-portal xdg-terminals
   ```

2. `git mv` the 12 home-targeting packages into `dotfiles/`.
3. Update `.stowrc` to point at the new location. Keep `--target` **absolute**
   (avoids the stow-version-dependent `~` expansion); add `--dir`:

   ```
   --dir=dotfiles
   --target=/home/connor
   ```

4. **Restow in the same sitting** — the move broke every existing symlink:

   ```bash
   # from repo root; .stowrc now supplies --dir=dotfiles --target=/home/connor
   stow bash hypr waybar kitty wofi mako ssh mimeapps alsa claude xdg-desktop-portal xdg-terminals
   # verify nothing dangles:
   find ~ ~/.config ~/.ssh -maxdepth 2 -xtype l
   # re-apply ssh perms (stow -D/-R can recreate the link):
   chmod 600 ~/.ssh/config
   ```

   The running Hyprland session is unaffected while links dangle, but don't reload
   Hyprland/waybar mid-move. This step must be repeated once on the desktop after
   pulling the branch.

Note: the root-targeted packages (`sddm`, `xone`, `discord-update`, `reflector`)
stay at the repo root — they leave stow entirely in Phase 3, so `--dir=dotfiles`
doesn't touch them.

## Phase 2 — Ansible scaffolding

- `inventory.yml`: single host `localhost` with `ansible_connection: local`; give it
  `ansible_host` aliases so `inventory_hostname` matches the machine hostname —
  simplest is one inventory entry per machine name and `--limit $(uname -n)`, or use
  a dynamic `hostname` fact. Decide during implementation; the requirement is that
  `host_vars/archlaptop.yml` applies on the laptop.
- `requirements.yml`: `community.general` (pacman, flatpak, npm), `kewlfft.aur`
  (AUR via yay). Bootstrap: `ansible-galaxy collection install -r requirements.yml`.
- Run as `connor`, `become: true` only on tasks that need root. `systemctl --user`
  enables use `systemd_service` with `scope: user` (no become).
- yay itself stays a manual bootstrap step on a fresh install (makepkg refuses to
  run as root; not worth automating for two machines).

## Phase 3 — Root-level files: stow packages → copy tasks

| Old stow package | Ansible tasks |
|---|---|
| `sddm/` | `copy` theme.conf → `/etc/sddm.conf.d/`, metadata.desktop → theme dir, weston.ini → `/var/lib/sddm/.config/`; root-owned 0644. Also copy `forest.jpg` into the repo (`system/files/sddm/`) and deploy it to the theme's `Backgrounds/` dir, updating metadata.desktop to point there — removes the last SDDM dependency on `/home`. Then `systemd` enable sddm + `set-default graphical.target` (command task with `changed_when` guard). |
| `xone/` | `copy` xone.conf → `/etc/modprobe.d/`, gated on a host var (e.g. `xone_enabled: true` on desktop only — confirm whether the laptop ever uses the adapter). |
| `discord-update/` | `copy` units → `/etc/systemd/system/` + enable timer. Consider per-host gating, and note the existing `pacman -Sy discord` partial-upgrade caveat — decide keep/drop while porting. |
| `reflector/` | `copy` reflector.conf → `/etc/xdg/reflector/` + enable timer. Already copy-based; delete README section 5c. |

**Migration gotchas (per machine, one-time):**

- Unstow the old root packages first (`sudo stow -D --target=/ sddm xone discord-update`)
  *before* the first playbook run — and set `follow: false` on every root `copy`
  task anyway, otherwise ansible writes **through** a leftover symlink back into the
  repo instead of replacing it.
- Remove the now-unneeded SDDM ACLs (desktop only):
  `setfacl -b /home/connor /home/connor/git /home/connor/git/arch-config /home/connor/Pictures /home/connor/Pictures/Wallpapers` and `setfacl -Rb /home/connor/git/arch-config/sddm` (paths as they exist there). Close the "does sddm need those permissions?" TODO.

## Phase 4 — Packages: lists → vars

- `group_vars/all.yml`: `packages_common`, `aur_packages`, `flatpak_apps`,
  `npm_globals`. `host_vars/*`: `packages_host` (ucode variant, nvidia set, xone-dkms,
  brightnessctl/power-profiles-daemon, etc.).
- Initial population: run `pacman -Qenq | sort` on **both** machines, then
  `comm -12` → common, `comm -23`/`comm -13` → per-host. Same for `-Qemq` (AUR).
- Tasks: `pacman` module for native (+ multilib enable via `blockinfile` on
  `/etc/pacman.conf` with `update_cache` after), `kewlfft.aur` for AUR,
  `flatpak_remote`+`flatpak` for apps, `npm global=yes` for globals.
- Flatpak `GTK_THEME` overrides: `command: flatpak override --user ...` with an
  idempotency check against `flatpak override --show`.
- **Workflow change (deliberate):** vars become the source of truth. Delete
  `packages/dump.sh` and the lists; replace with `scripts/check-drift.sh` that diffs
  `pacman -Qenq` against the merged vars and prints anything installed ad hoc that
  isn't declared (and vice versa).

## Phase 5 — README absorption

Port the remaining manual steps into tasks, then rewrite the README:

- ssh perms → `file` tasks (0700 `~/.ssh`, 0600 config).
- systemd user enables: `arch-update.timer`, `arch-update-tray.service`,
  `wallpaper-cycle.timer` (with `daemon_reload: true`).
- VSCode Flatpak `settings.json` (`~/.var/app/com.visualstudio.code/...`): deploy
  with `copy` + `force: false` — created on fresh installs, never clobbers a live
  file VSCode has since edited. This finally version-controls it.
- Delete stale README content: step 6 + the broken `claude-code-aur-symlink.md`
  links (claude is npm-managed now), the ACL section, sections 5a–5d.
- New README restore procedure: clone → bootstrap yay → `stow` dotfiles →
  `ansible-galaxy collection install -r` → `ansible-playbook -K site.yml`.
  Keep the Full System Update and Timeshift guidance as-is.

## Phase 6 (optional, same branch or follow-up) — per-host dotfiles hooks

- `hyprland.conf`: append `source = ~/.config/hypr/host.conf`; add
  `dotfiles/hypr/.config/hypr/hosts/{archlaptop,<desktop>}.conf` holding monitors
  and desktop-only autostarts (`steam -silent`, `discord --start-minimized`).
  An ansible task creates the symlink: `host.conf → hosts/{{ hostname }}.conf`
  (gitignore `host.conf`). Add a `monitor=,preferred,auto,1` fallback in the shared file.
- Fix `claude-remote-control.service`: `ExecStart=/usr/bin/claude`,
  `--name "%H"`, `WorkingDirectory=%h/claude-remote` — one unit valid on both machines.
- Drop (or vendor) waybar's dead `custom/media` module — `mediaplayer.py` doesn't exist.

## Verification & rollback

1. `ansible-lint system/` clean.
2. First run on the laptop: `ansible-playbook --check --diff -K site.yml` — review
   the drift it reports before applying anything.
3. `sudo timeshift --create` before the first real apply (matches existing practice).
4. After apply: log out/in through SDDM (highest-risk change), confirm
   `reflector.timer`/`wallpaper-cycle.timer` active, `find / -xtype l` spot-check on
   old stow targets (`/etc/sddm.conf.d`, `/etc/modprobe.d`, `/etc/systemd/system`).
5. Repeat on the desktop; expect its first `--check` run to be noisier.

## Suggested commit sequence on the branch

1. Phase 1 (restow move) — verify stow still works before anything else.
2. Phase 2 scaffolding + Phase 3 root files.
3. Phase 4 packages.
4. Phase 5 README rewrite.
5. Phase 6 extras.

Delete this file once the migration lands.
