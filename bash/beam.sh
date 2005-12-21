#!/bin/bash
#
# $Id: beam.sh,v 1.2 2005-12-21 21:08:59 mitch Exp $
#
# generate on-thy-fly-Torrents to copy data from A to B

set -e

if [ -z "$TRACKER" ] ; then
    echo \$TRACKER not set to annouce URL.
    exit 1
fi

TARGETHOST="$1"
shift

if [ -z "$TARGETHOST" ] ; then
    echo no TARGETHOST given.
    exit 1
fi
echo target "$TARGETHOST".

if [ -z "$@" ] ; then
    echo no FILES given.
    exit 1
fi

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
btmakemetafile "$TRACKER" "$@" --target $O_TORRENT > /dev/null
echo .

echo "(btdownloadheadless $O_TORRENT & echo \$! > $O_PID) #| grep \"^seed.*1 seen recently\" | while read I; do kill \$(cat $O_PID); done; rm $O_PID $O_TORRENT $O_SCREEN $I_SCREEN_LOCAL" > $O_SCREEN
chmod +x $O_SCREEN
echo "(cd $R_BEAMDIR; btdownloadheadless $I_TORRENT & echo \$! > $I_PID) #| grep \"^time left.*Download Succeeded\" | while read I; do sleep 60; kill \$(cat $I_PID); done; rm $I_TORRENT $I_PID $I_SCREEN" > $I_SCREEN_LOCAL
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
