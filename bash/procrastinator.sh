#!/bin/bash
#
# procrastination.sh - add penalty startup time to repeated program invocations
#
# Copyright (C) 2011  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
#
# This is based on an idea from http://xkcd.com/862/ and
# http://blog.xkcd.com/2011/02/18/distraction-affliction-correction-extensio/
#
# I keep wasting my time by repeatedly checking my mail and other stuff.
# This script checks if a specified time has passed.  If not, it waits
# for a penalty time (a tenth of the waiting time left) before it continues.
# Change the lockfile name to track different timestamps.
#
# Use it like this to throttle back your email habits to once every 10 minutes:
#
# alias mutt='procrastinator.sh 600 mail; mutt'

DBDIR=/tmp/procrastinator

help()
{
    echo "usage: procrastinator.sh <pause in seconds> <lockfile>"
    echo
}

if [ -z $1 ] ; then
    help
    exit 1
fi

if [ -z $2 ] ; then
    help
    exit 1
fi

LOCKDIR="$DBDIR"/"$USER"
mkdir -p "$LOCKDIR"

LOCKFILE="$LOCKDIR"/"$2"

if [ -e "$LOCKFILE" ]; then
    OLDTIME=$( stat -c %Y "$LOCKFILE" )
    NEWTIME=$( date +%s )
    DIFF=$(( $NEWTIME - $OLDTIME ))
    if [ $DIFF -lt $1 ] ; then
	echo PROCRASTINATION DETECTED, SLEEPING...
	sleep $(( ( $1 - $DIFF ) / 10 ))
    fi
fi

touch "$LOCKFILE"
