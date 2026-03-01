# Arch Dotfiles & Packages

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
```
