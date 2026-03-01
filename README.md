# Arch Dotfiles & Packages

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

## Dumping current packages

Run `dump.sh` to update the package lists:

```bash
~/git/arch-dotfiles/packages/dump.sh
```

This generates:
- `pkglist.txt` — explicitly installed native packages
- `pkglist-aur.txt` — explicitly installed AUR packages

## Restoring on a new machine

### 1. Install yay (AUR helper)

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

### 2. Install packages

```bash
sudo pacman -S --needed - < ~/git/arch-dotfiles/packages/pkglist.txt
yay -S --needed - < ~/git/arch-dotfiles/packages/pkglist-aur.txt
```

### 3. Symlink dotfiles with stow

```bash
cd ~/git/arch-dotfiles
stow bash hypr waybar kitty wofi
sudo stow --target=/ sddm
```

### 4. Set ACLs for SDDM

The `sddm` stow package symlinks files into `/etc/` and `/usr/share/` that point back into your home directory. The `sddm` user (which runs the greeter) cannot follow symlinks into `/home/connor` by default, so ACLs are needed to grant it read access to just the relevant files.

```bash
setfacl -m u:sddm:x /home/connor
setfacl -m u:sddm:x /home/connor/git
setfacl -m u:sddm:x /home/connor/git/arch-dotfiles
setfacl -R -m u:sddm:rX /home/connor/git/arch-dotfiles/sddm
setfacl -R -m d:u:sddm:rX /home/connor/git/arch-dotfiles/sddm
setfacl -m u:sddm:x /home/connor/Pictures
setfacl -m u:sddm:x /home/connor/Pictures/Wallpapers
setfacl -m u:sddm:r /home/connor/Pictures/Wallpapers/forest.jpg
```

> `x` on the directories allows traversal without listing. `rX` on the sddm package grants read on files and traverse on subdirectories. The `d:` prefix sets default ACLs so new files added to the sddm package inherit the same permissions automatically. The wallpaper ACL avoids duplicating the file for SDDM.
