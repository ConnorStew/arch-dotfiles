#!/bin/bash
# Dump explicitly installed packages into lists

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pacman -Qqen > "$SCRIPT_DIR/pkglist.txt"
pacman -Qqem > "$SCRIPT_DIR/pkglist-aur.txt"

echo "Saved:"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist.txt") native packages -> pkglist.txt"
echo "  $(wc -l < "$SCRIPT_DIR/pkglist-aur.txt") AUR packages    -> pkglist-aur.txt"
