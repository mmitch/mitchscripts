#!/bin/bash
#
# check_raid.sh - checks a RAID for errors
#
# Copyright (C) 2007,2011  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2 or later
#
# Based on information from
# http://gentoo-wiki.com/HOWTO_Gentoo_Install_on_Software_RAID#Data_Scrubbing
#
# This script will start data scrubbing for the given device and send a
# mail to root when errors are found.  Swap files are umounted before the
# check as the check won't work otherwise.  You should run this regularly,
# e.g. from cron(8).
#
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

SWAPPRIO=$(grep ^/dev/$MD /proc/swaps | awk '{print $5}')

[ $SWAPPRIO ] && swapoff /dev/$MD

read CURCOUNT < /sys/block/$MD/md/mismatch_cnt

echo check >> /sys/block/$MD/md/sync_action

STATUS=just_started
while [ "$STATUS" != "idle" ] ; do
	sleep 60
	read STATUS < /sys/block/$MD/md/sync_action
done

read ERRORS < /sys/block/$MD/md/mismatch_cnt

[ $SWAPPRIO ] && swapon -p $SWAPPRIO /dev/$MD

if [ "$ERRORS" -ne 0 ] ; then
	(
		date
		echo "this is the RAID check on device $MD"
		echo "/sys/block/$MD/md/mismatch_cnt"
		echo "showed $ERRORS errors after check"
		echo "($CURCOUNT before)"
	) | mail -s "errors during RAID check on $MD" root
fi
