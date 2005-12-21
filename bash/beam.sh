#!/bin/bash
#
# $Id: beam.sh,v 1.1 2005-12-21 20:39:52 mitch Exp $
#
# generate on-thy-fly-Torrents to copy data from A to B

set +e

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

BEAMDIR=~/beamdir
if [ ! -d $BEAMDIR ] ; then
    mkdir -p $BEAMDIR
    echo created $BEAMDIR.
fi

BEAMID=$(LANG=C date +%Y%m%y-%H%M%S)-$$
echo beamid $BEAMID.

echo -n creating torrent
btmakemetafile "$TRACKER" "$@" --target $BEAMDIR/$BEAMID.out.torrent > /dev/null
echo .
