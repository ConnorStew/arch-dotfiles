# Claude Code Voice Mode — ALSA `dsnoop` Conflict

**Error:**
```
ALSA lib pcm_dsnoop.c:572:(snd_pcm_dsnoop_open) [error.pcm] unable to open slave
arecord: main:850: audio open error: No such file or directory
```
Claude Code's `/voice` shows "Voice mode enabled (hold)" but recording produces no transcript.

## Cause

Two packages ship conflicting overrides for the ALSA `!default` PCM in
`/usr/share/alsa/alsa.conf.d/`, and both are named `99-*-default.conf`:

- `pipewire-pulse` → `99-pipewire-default.conf` (default → `type pipewire`)
- `alsa-plugins` → `99-pulseaudio-default.conf` (default → `type pulse`, `fallback "sysdefault"`)

Alphabetically `pulseaudio` loads after `pipewire`, so the PulseAudio-protocol
config wins. There's no real `pulseaudio` daemon on this system (just
PipeWire's compatibility socket), so the `pulse` plugin connection fails
silently and ALSA falls back to `sysdefault` — a raw hardware device that
PipeWire already owns exclusively. Opening it as a `dsnoop` slave then fails.

This breaks any ALSA app (`arecord`, and Claude Code's voice capture, which
shells out to `arecord`/`sox` on Linux) that uses the ALSA `default` device
directly, even though PipeWire/Pulse audio (`pactl`, browsers, etc.) works fine.

## Fix

Add a user-level ALSA config, which loads after all `alsa.conf.d/*` files and
settles the conflict regardless of package load order:

```
# ~/.asoundrc (symlinked via the alsa/ stow package)
pcm.!default {
    type pipewire
    hint.show on
    hint.description "Default Audio Device (PipeWire)"
}

ctl.!default {
    type pipewire
}
```

Managed via stow from the `alsa/` package in this repo:
```bash
cd ~/git/arch-config
stow --target=/home/connor alsa
```

Verify with:
```bash
arecord -d 2 -f S16_LE -r 16000 -c 1 /tmp/test.wav
```
No `dsnoop` error should appear, and the file should contain real audio data.

Also requires `alsa-utils` installed (provides `arecord`, which Claude Code's
voice mode falls back to when no native audio module or `sox` is present):
```bash
sudo pacman -S alsa-utils
```
