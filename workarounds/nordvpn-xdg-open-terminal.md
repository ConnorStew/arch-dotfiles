# NordVPN browser login doesn't reach the app (Brave / xdg-open)

## Problem
Logging into NordVPN via the browser redirects to a `nordvpn://` URL, which
`xdg-open` hands off to whichever `.desktop` entry claims the
`x-scheme-handler/nordvpn` MIME type. On Arch, both `nordvpn-bin` (CLI) and
`nordvpn-gui-bin` (GUI) are installed, but only the CLI package registers the
scheme:

```
$ xdg-mime query default x-scheme-handler/nordvpn
nordvpn.desktop
```

`/usr/share/applications/nordvpn.desktop` contains:
```
Exec=nordvpn click %u
Terminal=true
```

`Terminal=true` means the launcher needs to run this inside a terminal
emulator, via the `x-terminal-emulator` alternative. Arch doesn't ship
`update-alternatives` or set this up by default, so `/usr/bin/x-terminal-emulator`
doesn't exist:

```
$ gtk-launch nordvpn.desktop "nordvpn://test"
gtk-launch: error launching application: Unable to find terminal required for application
```

The launch fails silently from Brave's side — nothing visibly happens after
completing login in the browser.

## Solution
`/usr/bin/x-terminal-emulator` is a dead end here — modern GLib (2.88, confirmed
via `strings /usr/lib/libgio-2.0.so.0`) no longer uses that convention at all for
`Terminal=true` desktop entries. It checks for `xdg-terminal-exec` first, then
falls back to a hardcoded list (`ghostty`, `ptyxis`, `gnome-terminal`,
`mate-terminal`, `xfce4-terminal`, `tilix`, `konsole`, `nxterm`, `xterm`, `rxvt`,
`dtterm`) — kitty isn't in it, so symlinking `x-terminal-emulator` to kitty has
no effect on this failure.

The actual fix is installing `xdg-terminal-exec` (AUR, actively maintained —
this exact gap is its reason to exist) and telling it to prefer kitty:

```bash
yay -S xdg-terminal-exec
```

kitty's own `/usr/share/applications/kitty.desktop` already declares
`Categories=...;TerminalEmulator;` and `X-TerminalArgExec=--`, so it's
directly compatible — no compat-mode config needed. Preference is set via
`~/.config/xdg-terminals.list` (see the `xdg-terminals/` stow package in this
repo):

```
kitty.desktop
```

Verify with:
```bash
xdg-terminal-exec --print-id --print-cmd
gtk-launch nordvpn.desktop "nordvpn://test"   # should spawn: kitty -- nordvpn click nordvpn://test
```

### If you switch terminal emulators later
Update `xdg-terminals/.config/xdg-terminals.list` to the new terminal's
`.desktop` ID (it must declare `TerminalEmulator` category and either
`X-TerminalArgExec=` or work via xdg-terminal-exec's compat mode).
