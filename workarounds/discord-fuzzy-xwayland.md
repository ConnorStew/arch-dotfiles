# Discord renders fuzzy/soft under XWayland

## Problem
Discord's UI (text especially) looks fuzzy/soft/muddy on Hyprland, even though
both monitors are native 1080p at integer `scale 1` (so this is *not* the usual
fractional-scale upscaling blur). Discord is an Electron/Chromium app and the
packaged launcher runs it with no Wayland flags:

```
$ grep ^Exec /usr/share/applications/discord.desktop
Exec=/usr/bin/discord --url -- %u
```

With no Ozone flags, Electron defaults to its X11 backend and the window is
hosted by **XWayland** rather than presenting a native Wayland surface. Chromium's
font rendering / buffer handling through the X11 translation layer comes out soft
on Hyprland regardless of scale.

## Solution
Force Discord onto its native Ozone/Wayland backend so it draws a real Wayland
surface (crisp text):

```
--enable-features=UseOzonePlatform --ozone-platform=wayland
```

Quick test (nothing permanent) — fully quit Discord, then from a terminal:

```bash
discord --enable-features=UseOzonePlatform --ozone-platform=wayland
```

> Note: launching Discord from a terminal can pop a `write EIO` /
> "A JavaScript error occurred in the main process" dialog if the terminal
> closes out from under it — Electron fails writing a `console.warn` to the dead
> stdout. It's harmless and doesn't happen on a normal launcher start.

Make it permanent via a **user-level override** of the desktop entry.
`~/.local/share/applications/discord.desktop` shadows the system one through
XDG data-dir precedence, and adding the flags there needs no root and survives
package updates.

Do **not** edit `/usr/share/applications/discord.desktop` directly: it's
root-owned and the `discord-update` timer (`system/tasks/discord-update.yml`)
runs `pacman -Sy discord` ~30s after every boot, which would clobber it.

In this repo it's the `discord/` stow package
(`dotfiles/discord/.local/share/applications/discord.desktop`), a copy of the
system entry with only the `Exec` line changed:

```
Exec=/usr/bin/discord --enable-features=UseOzonePlatform --ozone-platform=wayland --url -- %u
```

Deploy and refresh the launcher cache:

```bash
stow discord
update-desktop-database ~/.local/share/applications
```

Verify the override wins:

```bash
grep ^Exec ~/.local/share/applications/discord.desktop   # should show the ozone flags
```
