#!/bin/bash
#
# fstrim.sh - trim filesystems
#
# Call with block devices, e.g. 'fstrim /dev/mapper/vg0-*'
#
# This script will check which of the given devices are currently
# mounted and will issue a TRIM command for every one that is.
# This script should be called daily or weekly from cron or anacron.
# Trimming via script has advantages over auto-trim via the 'discard'
# mount option, see http://blog.neutrino.es/2013/howto-properly-activate-trim-for-your-ssd-on-linux-fstrim-lvm-and-dmcrypt/
#
# BUGS: don't call on devices or mount paths containing shell metacharacters or the string " type "…

set -e

declare -A MOUNTPOINTS

while IFS= read -r LINE; do
    DEV="${LINE%% on *}"
    LINE="${LINE#$DEV on }"
    MOUNTPOINT="${LINE%% type *}"
    MOUNTPOINTS[$DEV]="$MOUNTPOINT"
done  < <(LANG=C mount)

for DEV in "${@}"; do
    MOUNTPOINT="${MOUNTPOINTS[$DEV]}"
    if [ "$MOUNTPOINT" ] ; then
	/sbin/fstrim "$MOUNTPOINT"
    fi
done
