#!/bin/bash
set -euo pipefail

WALLPAPER_DIR="$HOME/wallpapers"

mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))
[ ${#images[@]} -eq 0 ] && exit 0

current="$(awww query 2>/dev/null | grep -oP 'image: \K\S+' | head -1)"

candidates=()
for img in "${images[@]}"; do
    [ "$img" != "$current" ] && candidates+=("$img")
done
[ ${#candidates[@]} -eq 0 ] && candidates=("${images[@]}")

new="${candidates[RANDOM % ${#candidates[@]}]}"

awww img "$new" --transition-type random
