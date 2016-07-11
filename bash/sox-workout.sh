#!/bin/bash
#
# generate a combined workout soundtrack that contains audio markers at specified
# time intervals to go faster/harder/scooter or slower/chillax
#
# Copyright (C) 2016  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later
#
# usage:
#   sox-workout.sh input_file [input_file [...]]
#

# TODO: use getopts instead of hardcoded values
OUTPUT_FILE=${TMPDIR:-/tmp}/workout.mp3

# TODO: add per-file parameters like "-c 2" or "-c 2 -r 44100"
RAMP_UP_SOUND="~/Dropbox/ringtone/Freesound.org - Casio F-91W Hour Chime by Koyber.mp3"
CHILL_DOWN_SOUND="~/Dropbox/ringtone/Freesound.org - microwave ding.wav by Reitanna.mp3"

SLOW_DURATION=90
FAST_DURATION=180
TOTAL_DURATION=$(( 30 * 60 ))

# # # #

print_timed() {
    local SEC MIN HOUR
    let SEC=$1%60
    let MIN=$1/60
    let HOUR=$MIN/60
    let MIN=$MIN%60
    shift
    printf "%02d:%02d:%02d %s\n" $HOUR $MIN $SEC "$*"
}

# start with a slow period, first change is a ramp up
TIME=$SLOW_DURATION
TYPE=slow

CMDLINE="sox --multi-threaded -m \"|sox --combine sequence"
for FILE in "$@"; do
    CMDLINE=" $CMDLINE \\\"$FILE\\\""
done
CMDLINE="$CMDLINE -p\""

while [ $TIME -lt $TOTAL_DURATION ]; do
    if [ $TYPE = slow ]; then
	print_timed $TIME speedup
	CMDLINE="$CMDLINE \"|sox \\\"$RAMP_UP_SOUND\\\" -c 2 -p pad $TIME\""  # remix 1,1 ?
	TYPE=fast
	let TIME=$TIME+$FAST_DURATION
    else
	print_timed $TIME slowdown
	CMDLINE="$CMDLINE \"|sox \\\"$CHILL_DOWN_SOUND\\\" -c 2 -r 44100 -p pad $TIME\""  # remix 1,1 ?
	TYPE=slow
	let TIME=$TIME+$SLOW_DURATION
    fi
done

print_timed $TOTAL_DURATION end

CMDLINE="$CMDLINE \"$OUTPUT_FILE\" fade 0 $TOTAL_DURATION 10"

echo "now running:"
echo "$CMDLINE"
echo
eval "$CMDLINE"
echo "finished."
