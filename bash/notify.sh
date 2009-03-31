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
DZEN_FG=black
DZEN_BG=gray
DZEN_TIMEOUT=3

MSGFILE=~/.notify
MSGWAIT=5

WORKFILE="${MSGFILE}.work"

# wait for messages

while sleep "$MSGWAIT"; do
    if [ -s "$MSGFILE" ] ; then
	mv "$MSGFILE" "$WORKFILE"
	while read LINE; do
	    echo "$LINE" | "$DZEN_BIN" -fg "$DZEN_FG" -bg "$DZEN_BG" -fn "$DZEN_FONT" -p "$DZEN_TIMEOUT"
	done < "$WORKFILE"
	rm "$WORKFILE"
    fi
done

