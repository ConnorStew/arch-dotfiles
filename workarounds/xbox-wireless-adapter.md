# Xbox Wireless Adapter (045e:02fe) on Arch Linux

## Problem
The Xbox Wireless Adapter for Windows uses a MediaTek MT7612U chip, the same
chip found in some USB WiFi adapters. Linux loads the `mt76x2u` WiFi driver
instead of the correct `xone-dongle` driver, preventing the dongle from working.

## Solution
Blacklist `mt76x2u` and use the `xone` driver.

### Packages required
```
yay -S xone-dkms-git xone-dongle-firmware
sudo pacman -S linux-headers
```

### Workaround
`/etc/modprobe.d/xone.conf` is managed via stow from the `xone/` package in this repo:

```bash
cd ~/git/arch-dotfiles
sudo stow --target=/ xone
```

This symlinks `xone/etc/modprobe.d/xone.conf` → `/etc/modprobe.d/xone.conf`, which blacklists `mt76x2u`:

```
blacklist mt76x2u
```

Then load the driver:
```bash
sudo modprobe xone_dongle
```

### To pair a controller
1. Plug in the Xbox wireless adapter
2. Hold the Xbox button on the controller to power it on
3. The dongle LED will flash and pair automatically

### If it stops working after a kernel update
DKMS should rebuild automatically, but if not:
```
sudo dkms autoinstall
```
