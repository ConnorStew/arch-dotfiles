#!/bin/bash
# Dump explicitly installed packages into lists

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pacman -Qen > "$SCRIPT_DIR/pkglist.txt"
pacman -Qem > "$SCRIPT_DIR/pkglist-aur.txt"
flatpak list --app --columns=application,version > "$SCRIPT_DIR/pkglist-flatpak.txt"
npm list -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -I{} basename {} > "$SCRIPT_DIR/pkglist-npm.txt"

echo "Saved:"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist.txt") native packages  -> pkglist.txt"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist-aur.txt") AUR packages     -> pkglist-aur.txt"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist-flatpak.txt") Flatpak apps     -> pkglist-flatpak.txt"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist-npm.txt") npm globals      -> pkglist-npm.txt"
