#!/bin/bash
# $Id: check_raid.sh,v 1.5 2007-09-20 18:05:58 lalufu Exp $
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

if [ "$ERRORS" -ne "$CURCOUNT" ] ; then
	(
		date
		echo "this is the RAID check on device $MD"
		echo "/sys/block/$MD/md/mismatch_cnt"
		echo "showed $ERRORS errors after check"
		echo "($CURCOUNT before)"
	) | mail -s "errors during RAID check on $MD" root
fi
