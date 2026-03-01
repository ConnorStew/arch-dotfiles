# Claude Code — AUR Install Symlink Fix

**Error:** `installMethod is native, but claude command not found at /home/connor/.local/bin/claude`

**Cause:** The AUR package (`claude-code`) installs the binary to `/usr/bin/claude`, but Claude Code's internal checks expect it at `~/.local/bin/claude` (the npm install path).

**Fix:**

```bash
ln -s /usr/bin/claude ~/.local/bin/claude
```
