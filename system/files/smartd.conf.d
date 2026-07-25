# /etc/conf.d/smartd — read by smartd.service via EnvironmentFile.
#
# --savestates makes smartd persist each drive's attributes to
# {PREFIX}MODEL-SERIAL.TYPE.state. Without it smartd takes a fresh baseline
# every startup and can only report changes within a single session — useless
# on a machine that's powered off overnight, since a value that moved while it
# was off is silently adopted as the new normal. With it, "this counter went up"
# means since the last time smartd ran, across reboots.
#
# Note this is the *command-line* -s (savestates). The -s inside smartd.conf is
# a different, unrelated directive (self-test schedule).
SMARTD_ARGS="--savestates=/var/lib/smartmontools/smartd."
