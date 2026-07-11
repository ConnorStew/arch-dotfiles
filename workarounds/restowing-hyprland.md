# Hyprland Restowing

## Problem
Can't restow hyprland config file due to it running and auto generating a new version of it on deletion.

## Solution
Run `stow --adopt hypr` then just revert the file in git.