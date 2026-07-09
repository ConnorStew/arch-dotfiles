#!/bin/bash
set -euo pipefail

current="$(awww query 2>/dev/null | grep -oP 'image: \K\S+' | head -1 || true)"
[ -n "$current" ] && exit 0

WALLPAPER_DIR="$HOME/wallpapers"

mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))
[ ${#images[@]} -eq 0 ] && exit 0

new="${images[RANDOM % ${#images[@]}]}"

awww img "$new" --transition-type none
