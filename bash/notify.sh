#!/bin/sh
#
# simple X notification framework
#
# 2009 (C) by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2
#
# needs dzen2 from http://gotmor.googlepages.com/dzen
#

DZEN_BIN=/home/mitch/svn/dzen/dzen2
DZEN_FONT='-misc-fixed-medium-r-normal-*-13-*-*-*-*-*-*-*'
DZEN_FG='#ccc'
DZEN_BG='#222'
DZEN_TIMEOUT=5
DZEN_JUSTIFY=l

DZEN_FG_ERR='#fff'
DZEN_BG_ERR='#f00'

DZEN_FG_OK='#000'
DZEN_BG_OK='#0f0'

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
		OK:*)
		    FG="$DZEN_FG_OK"
		    BG="$DZEN_BG_OK"
		    ;;
		ERR:*)
		    FG="$DZEN_FG_ERR"
		    BG="$DZEN_BG_ERR"
		    ;;
		*)
		    FG="$DZEN_FG"
		    BG="$DZEN_BG"
		    ;;
	    esac
	    echo "$LINE" | "$DZEN_BIN" -fg "$FG" -bg "$BG" -fn "$DZEN_FONT" -p "$DZEN_TIMEOUT" -ta "$DZEN_JUSTIFY"
	done < "$WORKFILE"
	rm "$WORKFILE"

    fi
done

