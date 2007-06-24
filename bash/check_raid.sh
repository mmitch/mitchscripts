#!/bin/bash
# $Id: check_raid.sh,v 1.2 2007-06-24 12:27:12 mitch Exp $
#
# 2007 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL 
#
# checks a RAID for errors
# see http://gentoo-wiki.com/HOWTO_Gentoo_Install_on_Software_RAID#Data_Scrubbing
#
# usage: check_raid.sh <mdX>
#

MD=$1

abend()
{
	echo "$@" 1>&2
	exit 1
}

[ "$MD" ] || abend "usage: check_raid.sh <mdX>"
[ -d /sys/block/$MD ] || abend "RAID device $MD does not exist"

echo check >> /sys/block/$MD/md/sync_action

while [ "$(cat /sys/block/$MD/md/sync_action)" != "idle" ] ; do
	sleep 60
done

ERRORS="$(cat /sys/block/$MD/md/mismatch_cnt)"

if [ "$ERRORS" -gt 0 ] ; then
	(
		date
		echo "this is the RAID check on device $MD"
		echo "/sys/block/$MD/md/mismatch_cnt"
		echo "showed $ERRORS errors"
	) | mail -s "errors during RAID check on $MD" root
fi
