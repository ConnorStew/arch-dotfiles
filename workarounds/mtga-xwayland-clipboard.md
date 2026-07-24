# MTG Arena deck export never reaches Wayland apps

## Problem
Clicking "Export" on a deck in MTG Arena appears to do nothing: pasting into
Brave (Moxfield, Archidekt, …) yields an empty clipboard.

The copy actually works — it just lands in the **X11** clipboard and stops there.
Arena runs under Proton, so it's an XWayland client:

```
$ hyprctl clients -j | jq -r '.[] | "\(.class) xwayland=\(.xwayland)"'
steam_app_2141910 xwayland=true
brave-browser     xwayland=false
```

Right after an export, the two clipboards disagree:

```
$ xclip -o -selection clipboard
Commander
1 High Perfect Morcant (ECL) 229

Deck
19 Forest (UST) 216
...

$ wl-paste
Nothing is copied
```

Brave is a native Wayland client, so it pastes from the (empty) Wayland
clipboard and gets nothing.

## Cause
Hyprland's XWM only claims the Wayland selection while an **XWayland window
holds focus** — setting a Wayland selection requires a valid seat serial, which
only exists for a focused surface. Confirmed empirically: focusing the Arena
window and then claiming the X selection syncs to Wayland instantly, while the
same copy with a Wayland window focused does not sync at all.

Wine re-asserts X selection ownership around focus changes, so the
copy → alt-tab → paste sequence falls into that gap and the Wayland side ends up
with no offer at all.

This is the long-standing X11/Wayland clipboard split in Hyprland, not a config
error — see [hyprwm/Hyprland#6132](https://github.com/hyprwm/Hyprland/issues/6132)
and [discussion #11889](https://github.com/hyprwm/Hyprland/discussions/11889)
("a problem for quite a while now but wasn't ez to fix"). Verified on Hyprland
0.55.4 / xorg-xwayland 24.1.13.

## Solution
Pull the X11 clipboard across manually after exporting. `hyprland.conf` defines:

```
$clipsync = sh -c 'x=$(xclip -o -selection clipboard 2>/dev/null); [ -n "$x" ] && printf %s "$x" | wl-copy'
bind = $mainMod SHIFT, V, exec, $clipsync
```

So: hit Export in Arena → `SUPER SHIFT V` → paste into the browser as normal.
The `[ -n "$x" ]` guard means an empty X clipboard leaves the Wayland one alone
rather than blanking it.

`xclip` is declared in `system/group_vars/all.yml` (`packages_common`) for this.

## Rejected: wl-clip-persist
`wl-clip-persist --clipboard both` was tried first and reverted (commits
`21db869` / `10bc3fc`). It solves a *different* problem — keeping Wayland
clipboard contents alive after the source app **exits**. Here the source app is
still running and the content is in the wrong clipboard entirely, so it has no
effect.

## Notes
- The direction that matters here is X → Wayland. Wayland → X is broken the same
  way (`wl-copy` then `xclip -o` gives `Error: target STRING not available`),
  which would affect pasting *into* Arena; the same bind doesn't cover that.