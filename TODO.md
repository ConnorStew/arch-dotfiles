# TODO

- [ ] Try Ghostty: https://ghostty.org/

## Hyprland

- [ ] Check for Hyprland 0.54-compatible workspace overview plugin — hyprspace and hyprtasking both fail to build due to the 0.54 layout engine rewrite. Revisit in a few weeks.

## Packages

- [ ] Check out `arch-update` (AUR) — proper update notifier with tray icon, handles pacman + AUR + flatpak. Could replace the custom `discord-update` systemd timer.

## Brave

- [ ] Change `~/.config/brave-flags.conf` from `--password-store=basic` to `--password-store=kwallet6` (or `gnome-libsecret` if using a GNOME keyring). Currently set to `basic`, which stores passwords unencrypted.
