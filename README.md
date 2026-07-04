# Arch Dotfiles & Packages

## Scripts (`scripts/`)

Useful utility scripts — not stowed, run manually.

| Script | Description |
|--------|-------------|
| `sync-notes.sh` | Bidirectional rclone sync for Obsidian notes and DnD folder to Google Drive. Does a dry run first with confirmation. Usage: `./scripts/sync-notes.sh [obsidian\|dnd\|both]` |

## Removing a Stowed File

1. Delete the file from the repo
2. Remove the dangling symlink from your home directory
3. Restow the package to verify it's clean

```bash
rm hypr/.config/hypr/some-file.sh
rm ~/.config/hypr/some-file.sh
stow --target=/home/connor hypr -v
```

## Stowing New Files

Simulate:

```bash
stow --target=/home/connor hypr -v --simulate
```

Apply:

```bash
stow  --target=/home/connor hypr -v
```

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
- [Claude Code AUR Symlink](workarounds/claude-code-aur-symlink.md) — AUR install lands in `/usr/bin/`, needs symlink to `~/.local/bin/`

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
sudo npm update -g
```

### 6. Dump updated package lists

```bash
bash ~/git/arch-config/packages/dump.sh
```

### Notes

- When updating kernel + NVIDIA + `xone-dkms`, always update all three together and reboot immediately after.
- Reboot after any update that includes `libdrm`, `mesa`, `nvidia`, or the kernel — these touch the GPU/display stack and need a clean reload.
- For hardware failure protection, use rclone to back up to Google Drive (see `scripts/sync-notes.sh`).

## Dumping current packages

Run `dump.sh` to update the package lists:

```bash
~/git/arch-config/packages/dump.sh
```

This generates:
- `pkglist.txt` — explicitly installed native packages
- `pkglist-aur.txt` — explicitly installed AUR packages

## Restoring on a new machine

### 1. Clone the repo

```bash
git clone git@github.com:ConnorStew/arch-config.git ~/git/arch-config
```

### 2. Install yay (AUR helper)

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

### 3. Install packages

```bash
sudo pacman -S --needed - < ~/git/arch-config/packages/pkglist.txt
yay -S --needed - < ~/git/arch-config/packages/pkglist-aur.txt
```

### 4. Symlink dotfiles with stow

```bash
cd ~/git/arch-config
stow bash hypr waybar kitty wofi mimeapps mako alsa claude
sudo stow --target=/ sddm
sudo stow --target=/ xone
sudo stow --target=/ discord-update
```

### 4a. Enable arch-update's timer and tray icon

`mako` (notification daemon) and `arch-update` are both installed by step 3. Mako is autostarted via `hyprland.conf` (`exec-once = mako`); `arch-update` uses it to notify about available package updates. Enable arch-update's timer and tray icon:

```bash
systemctl --user enable --now arch-update.timer
systemctl --user enable --now arch-update-tray.service
```

### 4b. Enable Discord auto-update timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now discord-update.timer
```

### 4c. Deploy reflector config and enable mirror auto-update

The reflector service uses `ProtectHome=true` so symlinks into `/home` don't work — deploy as a plain copy instead:

```bash
sudo cp ~/git/arch-config/reflector/etc/xdg/reflector/reflector.conf /etc/xdg/reflector/reflector.conf
sudo chown root:root /etc/xdg/reflector/reflector.conf
sudo systemctl enable --now reflector.timer
```

To run immediately:

```bash
sudo systemctl start reflector.service
```

### 4d. Stow SSH config

SSH requires strict permissions or it will refuse to use the files:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
stow --target=/home/connor ssh
chmod 600 ~/.ssh/config
chmod 600 ~/git/arch-config/ssh/.ssh/config
```

### 5. Fix Claude Code symlink (AUR install)

The AUR package installs to `/usr/bin/claude` but Claude Code expects `~/.local/bin/claude`:

```bash
ln -s /usr/bin/claude ~/.local/bin/claude
```

See [workarounds/claude-code-aur-symlink.md](workarounds/claude-code-aur-symlink.md) for details.

### 6. Set ACLs for SDDM

The `sddm` stow package symlinks files into `/etc/` and `/usr/share/` that point back into your home directory. The `sddm` user (which runs the greeter) cannot follow symlinks into `/home/connor` by default, so ACLs are needed to grant it read access to just the relevant files.

```bash
setfacl -m u:sddm:x /home/connor
setfacl -m u:sddm:x /home/connor/git
setfacl -m u:sddm:x /home/connor/git/arch-config
setfacl -R -m u:sddm:rX /home/connor/git/arch-config/sddm
setfacl -R -m d:u:sddm:rX /home/connor/git/arch-config/sddm
setfacl -m u:sddm:x /home/connor/Pictures
setfacl -m u:sddm:x /home/connor/Pictures/Wallpapers
setfacl -m u:sddm:r /home/connor/Pictures/Wallpapers/forest.jpg
```

> `x` on the directories allows traversal without listing. `rX` on the sddm package grants read on files and traverse on subdirectories. The `d:` prefix sets default ACLs so new files added to the sddm package inherit the same permissions automatically. The wallpaper ACL avoids duplicating the file for SDDM.

### 7. Flatpak apps and fixups

Install the Flatpak apps you use (VSCode, Brave, Spotify, etc.), then apply the following fixups — both are lost on a fresh install since they live outside this repo.

Let VSCode's terminal see host binaries (`pacman`, `flatpak`, etc.) from inside the Flatpak sandbox by adding `flatpak-spawn --host` wrapping in `~/.var/app/com.visualstudio.code/config/Code/User/settings.json`.

Fix GTK native dialogs defaulting to light theme in Flatpak apps:

```bash
flatpak override --user --env=GTK_THEME=Adwaita:dark com.visualstudio.code
flatpak override --user --env=GTK_THEME=Adwaita:dark com.brave.Browser
flatpak override --user --env=GTK_THEME=Adwaita:dark com.spotify.Client
```
