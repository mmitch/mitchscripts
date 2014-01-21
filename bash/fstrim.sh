#!/bin/bash
#
# fstrim.sh - trim filesystems
#
# Call with block devices, e.g. 'fstrim /dev/mapper/vg0-*'
#
# This script will check which of the given devices are currently
# mounted and will issue a TRIM command for every one that is.
# This script should be called daily or weeky from cron or anacron.
# Trimming via script has advantages over auto-trim via the 'discard'
# mount option, see http://blog.neutrino.es/2013/howto-properly-activate-trim-for-your-ssd-on-linux-fstrim-lvm-and-dmcrypt/
#
# BUGS: don't try devices or mount paths either whitespace or regexp special characters…

set -e

for DEV in "${@}"; do
    DIR="$(LANG=C mount | grep "^$DEV" | sed -e "s,^$DEV on /,/," -e 's, type .*$,,')"
    if [ "$DIR" ] ; then
	/sbin/fstrim $DIR
    fi
done
