# TODO

- [ ] Try Ghostty: https://ghostty.org/

## Hyprland

- [ ] Check for Hyprland 0.54-compatible workspace overview plugin — hyprspace and hyprtasking both fail to build due to the 0.54 layout engine rewrite. Revisit in a few weeks.

## Brave

- [ ] Change `~/.config/brave-flags.conf` from `--password-store=basic` to `--password-store=kwallet6` (or `gnome-libsecret` if using a GNOME keyring). Currently set to `basic`, which stores passwords unencrypted.

## Ansible migration (PLAN.md)

Phase 3 is implemented (`system/`), but not yet applied. Before first apply on the **laptop**:

- [ ] Unstow the old root stow symlinks first (note the `.stowrc` `--dir=dotfiles` override):
      `cd ~/git/arch-config && sudo stow -D --dir=. --target=/ sddm discord-update`
      (`xone`/`reflector` aren't stowed on the laptop; `theme.conf`/`reflector.conf` are already plain files)
- [ ] Preview: `cd system && ansible-playbook site.yml --limit "$(uname -n)" --check --diff -K`
- [ ] Apply: `ansible-playbook site.yml --limit "$(uname -n)" -K`
- [ ] After a confirmed successful apply, delete the old root stow packages from the repo (`sddm/`, `xone/`, `discord-update/`, `reflector/`)
- [ ] Repeat the unstow + apply on the **desktop** (create `host_vars/<hostname>.yml` from `desktop.yml.example`, add it to `inventory.yml`); expect its `--check` run to be noisier
- [ ] Confirm `xone_enabled` on the laptop — set to `false` for now (does the laptop ever use the Xbox adapter?)

## Other

- [ ] Does ssdm need those permissions espically to the wallpaper?
- [ ] Consider using this instead of stow: https://www.chezmoi.io/
- [ ] Check awww animated wallpapers.