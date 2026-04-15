#!/usr/bin/env bash
set -e

SYNC_TARGET="${1:-both}"

sync_obsidian() {
    echo "=== DRY RUN: Obsidian Notes ==="
    rclone bisync ~/obsidian "gdrive:Obsidian Notes" --dry-run --progress --exclude ".obsidian/workspace*.json"
    
    echo -e "\n==================================="
    read -p "Proceed with Obsidian sync? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n=== SYNCING: Obsidian Notes ==="
        rclone bisync ~/obsidian "gdrive:Obsidian Notes" --progress --exclude ".obsidian/workspace*.json"
        echo -e "\n=== Obsidian Sync Complete ==="
    else
        echo "Obsidian sync cancelled."
        return 1
    fi
}

sync_dnd() {
    echo "=== DRY RUN: DnD ==="
    rclone bisync ~/dnd "gdrive:DnD" --dry-run --progress
    
    echo -e "\n==================================="
    read -p "Proceed with DnD sync? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\n=== SYNCING: DnD ==="
        rclone bisync ~/dnd "gdrive:DnD" --progress
        echo -e "\n=== DnD Sync Complete ==="
    else
        echo "DnD sync cancelled."
        return 1
    fi
}

case "$SYNC_TARGET" in
    obsidian)
        sync_obsidian
        ;;
    dnd)
        sync_dnd
        ;;
    both)
        sync_obsidian
        echo ""
        sync_dnd
        ;;
    *)
        echo "Usage: $0 [obsidian|dnd|both]"
        echo "  obsidian - sync only Obsidian Notes"
        echo "  dnd      - sync only DnD"
        echo "  both     - sync both (default)"
        exit 1
        ;;
esac
