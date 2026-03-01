#!/bin/bash

# Kill other wofi
killall wofi 2>/dev/null

# Get cursor position
cursor_text="$(hyprctl cursorpos)"
read -r cursor_x cursor_y <<< "$(echo "$cursor_text" | tr -d ',')"

# Get monitor data
monitor_info=$(hyprctl monitors -j)
monitor=$(echo $monitor_info | jq ".[] | select ($cursor_x >= .x and $cursor_x < (.x + .width))")

mon_x=$(echo "$monitor" | jq '.x')
mon_width=$(echo "$monitor" | jq '.width')
mon_height=$(echo "$monitor" | jq '.height')

# Get relative position of cursor to the monitor
rel_x=$((cursor_x - mon_x - (mon_width * 50 / 100)))
rel_y=$((cursor_y - (mon_height * 50 / 100)))

# x/y
if [[ "$args_set" == true ]]; then\
    command_x=$x
    command_y=$y
else
    command_x=$rel_x
    command_y=$rel_y
fi

# Run Wofi
wofi &
wofi_pid=$!

# Find Wofi window address
for i in {1..20}; do
  wofi_address=$(hyprctl clients -j | jq -r '.[] | select(.class=="wofi") | .address')
  if [[ "$wofi_address" != "null" && -n "$wofi_address" ]]; then break; fi
  sleep 0.1
  hyprctl clients -j
done

if [[ -n "$wofi_address" ]]; then
    command="hyprctl dispatch movewindowpixel -- "
    if [[ "$1" == "top_left" ]]; then
        offset_x=$(( mon_x + 3))
        command+="exact $offset_x 38, address:$wofi_address"  
    else
        command+="$rel_x $rel_y, address:$wofi_address"
    fi
    
    $command
else
    echo "Wofi window not found."
fi

while sleep 0.2; do
    focused_app=$(hyprctl activewindow -j | jq -r '.class')
    # If Wofi lost focus, kill it
    if [[ "$focused_app" != "wofi" ]]; then
        kill $wofi_pid 2>/dev/null
        break
    fi
done