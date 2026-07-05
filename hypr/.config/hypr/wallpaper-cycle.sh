#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="$HOME/wallpapers"

mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))
[ ${#images[@]} -eq 0 ] && exit 0

new="${images[RANDOM % ${#images[@]}]}"

awww img "$new" --transition-type random
