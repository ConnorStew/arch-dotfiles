
# Restoring on a new machine

Start from a standard Arch **base** install (via `archinstall` or manual `pacstrap base linux …`). That already provides the baseline packages (`base`, `linux`, `grub`, `sudo`, `networkmanager`, …) that the playbook deliberately doesn't manage.

## 1. Clone the repo

```bash
sudo pacman -S --needed git
git clone git@github.com:ConnorStew/arch-dotfiles.git ~/git/arch-dotfiles
```

## 2. Bootstrap yay (AUR helper)

`makepkg` refuses to run as root, so yay is a one-time manual bootstrap:

```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

## 3. Install the tools to run the playbook

```bash
sudo pacman -S --needed ansible stow
ansible-galaxy collection install -r ~/git/arch-dotfiles/system/requirements.yml
```

## 4. Stow the dotfiles

```bash
cd ~/git/arch-dotfiles
stow alsa bash hypr kitty mako mimeapps ssh waybar wofi xdg-desktop-portal xdg-terminals
```

## 5. Set up host vars 

On a new machine whose hostname isn't yet known to the playbook:

1. Copy an existing host_vars file and fill it in (nvidia set, `xone_enabled`, `sddm_greeter_weston`, etc.).
2. Add that hostname to `system/inventory.yml`.

### 6. Run the playbook

```bash
cd system
ansible-playbook site.yml --limit "$(uname -n)" --check --diff -K   # preview
ansible-playbook site.yml --limit "$(uname -n)" -K                  # apply
```

This installs native packages, enables SDDM/reflector/discord-update, sets ssh perms, deploys and enables the user units, installs flatpaks, and applies everything else. Multilib (for Steam) is enabled by the playbook — no manual `pacman.conf` edit needed.

### 7. Install AUR packages manually

AUR packages are **not** installed by the playbook — it only lists the missing ones so you can review each PKGBUILD first (see the `Report AUR packages needing manual installation` task output). Install them by hand:

```bash
yay -S <pkg> …
```

Then re-run `system/scripts/check-drift.py` to confirm nothing's left declared-but-missing.