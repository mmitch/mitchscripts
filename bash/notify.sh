#!/bin/sh
#
# simple X notification framework
#
# Copyright (C) 2009, 2013, 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
# needs dzen2 from http://gotmor.googlepages.com/dzen
#

DZEN_BIN=dzen2
DZEN_FONT='fixed-11'
DZEN_JUSTIFY=l

DZEN_EVENTS='button1=exit:0' # kill on left click

MSGFILE=~/.notify
MSGWAIT=5

WORKFILE="${MSGFILE}.work"

# clean up old messages

rm -f "$MSGFILE"

# wait for new messages

while sleep "$MSGWAIT"; do
    if [ -s "$MSGFILE" ] ; then

	# process messages
	mv "$MSGFILE" "$WORKFILE"
	while read LINE; do
	    case "$LINE" in

		# urgent non-mail messages
		OK:*)
		    FG="#000"
		    BG="#0f0"
		    TIMEOUT=10
		    ;;

		ERR:*)
		    FG="#fff"
		    BG="#f00"
		    TIMEOUT=15
		    ;;

		# Check_MK status mails:
		*Check_MK:*FLAPPINGSTART|*Check_MK:*PROBLEM)
		    FG="#ba6"
		    BG="#311"
		    TIMEOUT=5
		    ;;
		*Check_MK:*FLAPPINGSTOP|*Check_MK:*RECOVERY)
		    FG="#b94"
		    BG="#131"
		    TIMEOUT=5
		    ;;

		# plain default
		*)
		    FG="#ccc"
		    BG="#222"
		    TIMEOUT=5
		    ;;
	    esac
	    echo "$LINE" | "$DZEN_BIN" -fg "$FG" -bg "$BG" -fn "$DZEN_FONT" -p "$TIMEOUT" -ta "$DZEN_JUSTIFY" -e "$DZEN_EVENTS"
	done < "$WORKFILE"
	rm "$WORKFILE"

    fi
done

