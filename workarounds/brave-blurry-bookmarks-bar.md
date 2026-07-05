# Brave Bookmarks Bar Blurry/Pixelated

## Problem
The bookmarks bar (and sometimes non-fullscreen video) renders blurry/pixelated
when hardware acceleration is enabled. Known upstream Chromium/Brave rendering
bug, not specific to this machine — no permanent fix upstream yet.

## Workarounds
- Toggle the bookmarks bar off and back on: `Ctrl+Shift+B` twice. Often clears
  it immediately without a restart.
- Disable hardware acceleration in `brave://settings/system`. Fixes it
  permanently but loses GPU-accelerated rendering.
- Restart Brave. Sometimes self-resolves temporarily, but recurs later
  (also seen after waking from screensaver on Linux).

## References
- https://github.com/brave/brave-browser/issues/29946
- https://github.com/brave/brave-browser/issues/52069
