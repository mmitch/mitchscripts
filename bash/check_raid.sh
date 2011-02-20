#!/bin/bash
#
# check_raid.sh - checks a RAID for errors
#
# Copyright (C) 2007,2011  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2 or later
#
#
# usage: check_raid.sh <mdX>
#
#
# Based on information from
# http://gentoo-wiki.com/HOWTO_Gentoo_Install_on_Software_RAID#Data_Scrubbing
#
# This script will start data scrubbing for the given device and send a
# mail to root when errors are found.  Swap files are umounted before the
# check as the check won't work otherwise.  You should run this regularly,
# e.g. from cron(8).
#
# PLEASE NOTE:
# Devices in read-only-mode are skipped.  They can't be scrubbed as this might
# change data.  They are not put to read-write-mode!
#
# You can find your read-only devices this way:
# $ grep auto-read-only /proc/mdstat
#

# error-exit routine
abend()
{
	echo "$@" 1>&2
	exit 1
}

# check commandline parameters
MD=$1
[ "$MD" ] || abend "usage: check_raid.sh <mdX>"
[ -d /sys/block/$MD ] || abend "RAID device $MD does not exist"

# check if RAID is in read-only-mode
if grep -q "^${MD} : .*auto-read-only" /proc/mdstat ; then
    # in this case, we would get "write error: Device or resource busy"
    # no need to do anything then
    #
    # TODO: alternatively set RAID to r/w-mode?
    exit 0
fi

# umount swap if available and retain swap priority
SWAPPRIO=$(grep ^/dev/$MD /proc/swaps | awk '{print $5}')
[ $SWAPPRIO ] && swapoff /dev/$MD

# read old error count
read CURCOUNT < /sys/block/$MD/md/mismatch_cnt

# start the check
echo check >> /sys/block/$MD/md/sync_action

# check every 60 seconds for end of check
STATUS=just_started
while [ "$STATUS" != "idle" ] ; do
	sleep 60
	read STATUS < /sys/block/$MD/md/sync_action
done

# read new error count
read ERRORS < /sys/block/$MD/md/mismatch_cnt

# re-enable swap if needed
[ $SWAPPRIO ] && swapon -p $SWAPPRIO /dev/$MD

# mail errors to root
if [ "$ERRORS" -ne 0 ] ; then
	(
		date
		echo "this is the RAID check on device $MD"
		echo "/sys/block/$MD/md/mismatch_cnt"
		echo "showed $ERRORS errors after check"
		echo "($CURCOUNT before)"
	) | mail -s "errors during RAID check on $MD" root
fi
