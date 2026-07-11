## Stow (dotfiles)

`.stowrc` supplies `--dir`/`--target`, so no flags are needed:

```bash
cd ~/git/arch-dotfiles
stow hypr            # (re)stow a package
stow -D hypr         # unstow
stow -n hypr -v      # simulate
```

Stow or unstow **all** packages at once (`ls dotfiles` supplies the package names, since `.stowrc` already sets `--dir=dotfiles`):

```bash
cd ~/git/arch-dotfiles
stow $(ls dotfiles)      # stow every package
stow -D $(ls dotfiles)   # unstow every package
stow -R $(ls dotfiles)   # restow (unstow + stow) every package
```

Removing a file from a package:

1. Delete it from `dotfiles/<pkg>/…`
2. Remove the dangling symlink from `$HOME`
3. Restow to verify it's clean (`stow hypr`)

> Root-level config (SDDM, xone, discord-update, reflector) is **not** stow anymore — it's deployed by the Ansible playbook as root-owned copies. Don't `stow --target=/` anything; that recreates the symlink-into-repo problems this layout removed.
