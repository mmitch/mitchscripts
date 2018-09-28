#!/bin/bash

# Delete original or reencoded video, whichever is smaller.
#
# Copyright (C) 2018  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#
# When reencoding videos to .mkv, keep the original or the .mkv,
# whichever is smaller.  Scans the current directory for *.mkv and
# acts accordingly.

for MKV in *.mkv; do

    [ "$(lsof "$MKV" | wc -l)" = 0 ] || continue # file is still being written
    
    MKVSIZE=$(stat -c%s "$MKV")
    [ "$MKVSIZE" -gt 0 ] || continue
    
    ORIG="${MKV%.mkv}"
    [ -e "$ORIG" ] || continue
    
    ORIGSIZE=$(stat -c%s "$ORIG")
    [ "$ORIGSIZE" -gt 0 ] || continue

    SAVING=$(( "$ORIGSIZE" - "$MKVSIZE" ))

    # file got bigger => keep original
    if [ $SAVING -lt 0 ]; then
	echo ">100%    $ORIG"
	rm "$MKV"
	continue
    fi

    # more than 100MB saved => delete original
    if [ $SAVING -gt 100000000 ]; then 
	echo "-100MB   $ORIG"
	rm "$ORIG"
	continue
    fi
    
    RATIO=$(( ( "$MKVSIZE" * 100 ) / "$ORIGSIZE" ))

    # max. 2% savings => keep original
    if [ $RATIO -gt 97 ]; then
	echo "> 97%    $ORIG"
	rm "$MKV"
	continue
    fi

    # min. 3% savings => delete original
    echo "< 98%    $ORIG"
    rm "$ORIG"

#    printf '%d / %d%% - %s -> %s\n' $SAVING $RATIO "$ORIG" "$MKV"
done
