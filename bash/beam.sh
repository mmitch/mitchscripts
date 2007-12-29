#!/bin/bash
#
# generate on-thy-fly-torrents to copy data from A to B
#
# 2005 (c) by Christian Garbs <mitch@cgarbs.de>
#
# beam.sh <target> <file>
#
# depends:
#  - bittornado (both hosts)
#  - screen (both hosts)
#  - ssh, scp (only source host)
#
# recommends:
#  - key authentication or ssh-agent
#
# TODO:
#  - check free disk space on target
#  - multicopy (multiple target hosts)
#

set -e

if [ -z "$TRACKER" ] ; then
    echo \$TRACKER not set to annouce URL.
    exit 1
fi

TARGETHOST="$1"
if [ -z "$TARGETHOST" ] ; then
    echo no TARGETHOST given.
    exit 1
fi
shift
echo target "$TARGETHOST".

FILE="$1"
if [ -z "$FILE" ] ; then
    echo no FILE given.
    exit 1
fi
shift
FILEPATH="$(dirname "$FILE")"
FILENAME="$(basename "$FILE")"
echo filename $FILENAME.
echo path $FILEPATH.

R_BEAMDIR=beamdir
L_BEAMDIR=~/$R_BEAMDIR
if [ ! -d $L_BEAMDIR ] ; then
    mkdir -p $L_BEAMDIR
    echo created $L_BEAMDIR.
fi

BEAMID=$(LANG=C date +%Y%m%y-%H%M%S)-$$
echo beamid $BEAMID.
O_TORRENT=$L_BEAMDIR/$BEAMID.out.torrent
O_PID=$L_BEAMDIR/$BEAMID.out.pid
O_SCREEN=$L_BEAMDIR/$BEAMID.out.sh
I_TORRENT=$R_BEAMDIR/$BEAMID.in.torrent
I_PID=$R_BEAMDIR/$BEAMID.in.pid
I_SCREEN=$R_BEAMDIR/$BEAMID.in.sh
I_SCREEN_LOCAL=$L_BEAMDIR/$BEAMID.in.sh

echo -n creating torrent
(cd $FILEPATH; btmakemetafile "$TRACKER" "$FILENAME" --target $O_TORRENT > /dev/null)
echo .

echo "(cd $FILEPATH; btdownloadheadless $O_TORRENT & echo \$! > $O_PID) | grep -m1 \"^seed.*1 seen recently\"; kill \$(cat $O_PID); rm $O_PID $O_TORRENT $O_SCREEN $I_SCREEN_LOCAL" > $O_SCREEN
chmod +x $O_SCREEN
echo "(btdownloadheadless $I_TORRENT & echo \$! > $I_PID) | grep -m50 \"^time left.*Download Succeeded\"; kill \$(cat $I_PID); rm $I_TORRENT $I_PID $I_SCREEN" > $I_SCREEN_LOCAL
chmod +x $I_SCREEN_LOCAL

echo -n copying data
ssh "$TARGETHOST" "mkdir -p $R_BEAMDIR" > /dev/null
scp $O_TORRENT "$TARGETHOST":$I_TORRENT > /dev/null
scp $I_SCREEN_LOCAL "$TARGETHOST":$I_SCREEN > /dev/null
echo .

echo -n starting torrents
screen -dmS beam-$BEAMID $O_SCREEN
ssh "$TARGETHOST" "screen -dmS beam-$BEAMID $I_SCREEN"
echo .
