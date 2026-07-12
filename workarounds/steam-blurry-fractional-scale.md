# Steam renders blurry on the laptop's fractional-scale monitor

## Problem
On `archlaptop`, eDP-1 runs at fractional scale 1.5 (auto-detected, no monitor
rule — 1.5 is the comfortable UI size and is kept deliberately). Steam's UI
looked soft/blurry there, while it's fine on the desktop's integer-scale
monitors.

Steam's interface is CEF-based with **no native Wayland backend** — it always
runs through XWayland, and XWayland doesn't support `fractional-scale-v1`. On
a fractionally scaled output Hyprland therefore renders it at an integer scale
and downscales the buffer to fit = guaranteed blur. No Steam launch flag can
fix this (there is no Wayland mode to switch to — unlike Discord, whose
identical-looking blur was just missing Ozone flags, see
`workarounds/discord-fuzzy-xwayland.md`).

## Solution
One setting in the stowed `hyprland.conf` (shared by both hosts — no per-host
files):

```
xwayland {
    force_zero_scaling = true
}
```

XWayland clients now render at 1x — pixel-perfect crisp — instead of being
downscaled by Hyprland. Native Wayland apps are unaffected, and on the
desktop's integer-scale monitors the setting is a no-op, so it's safe shared.

At 1x Steam comes out **small** next to the 1.5x desktop. That's the accepted
tradeoff: `steam -forcedesktopscaling 1.5` was tried as compensation and *no
longer does anything* in the current Steam client (tested 2026-07), and
there's no other working knob for Steam's overall UI scale on XWayland.
(Steam's Big Picture mode scales fine on its own if the small desktop UI ever
becomes a real problem.)

Note `force_zero_scaling` applies to ALL XWayland apps: anything else running
under XWayland on the laptop will also render 1x-crisp-but-small. Most apps in
use are native Wayland, so in practice only Steam is affected; per-app zoom
(e.g. Ctrl+= in Chromium-based apps) is the knob if another XWayland app needs
resizing.
