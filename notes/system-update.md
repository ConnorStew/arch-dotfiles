
# Full System Update

## 1. Snapshot with Timeshift

Always take a snapshot before a full update, especially if the kernel, NVIDIA, or GCC is involved:

```bash
sudo timeshift --create --comments "Before full system update"
```

Delete it once the system is confirmed stable after reboot:

```shell
sudo timeshift --list
timeshift --delete  --snapshot '<name>'
```

## 2. Update native packages

```bash
sudo pacman -Syu
```

## 3. Check and update AUR packages

Before updating, review the PKGBUILDs for anything suspicious — especially check that sources download from expected upstream URLs with matching checksums:

```bash
yay -Syu
```

yay will show diffs for changed PKGBUILDs. Review before confirming.

## 4. Update Flatpak apps

```bash
flatpak update
```

## 5. Update npm globals

```bash
sudo npm update -g --allow-scripts=@anthropic-ai/claude-code
```

## 6. Reconcile the package vars

If the update added or removed anything you want tracked, edit the vars and confirm with:

```bash
system/scripts/check-drift.py
```

## Notes

- When updating kernel + NVIDIA + `xone-dkms`, always update all three together and reboot immediately after.
- Reboot after any update that includes `libdrm`, `mesa`, `nvidia`, or the kernel — these touch the GPU/display stack and need a clean reload.
- For hardware failure protection, use rclone to back up to Google Drive (see `scripts/sync-notes.sh`).