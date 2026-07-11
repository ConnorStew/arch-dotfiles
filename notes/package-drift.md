## Package drift

Package vars in `system/group_vars/all.yml` and `system/host_vars/<hostname>.yml` are the source of truth. To see what's installed but not declared (or vice versa):

```bash
system/scripts/check-drift.py
```

It diffs native (`pacman -Qenq`), AUR (`pacman -Qemq`), flatpak, and npm globals against the vars, ignoring the Arch install-time baseline and `*-debug` packages. When you install something new and want to keep it, add it to the appropriate var (`packages_common`/`packages_host`, `aur_packages`/`aur_host`, `flatpak_apps`, `npm_globals`) and re-run to confirm it's in sync.
