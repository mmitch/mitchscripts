#!/bin/bash
#
# sync local music file store to trekstor mobile player
#
# Copyright (C) 2012  Christian Garbs <mitch@cgarbs.de>
# licensed under the GNU GPL v3 or later

### configuration

TREKDIR=/mnt/usb_part_sync
LOCALDIR=/home/mitch/TREKSTOR

### checks + setup

if [ ! -d $TREKDIR ] ; then
    echo USB mount point $TREKDIR missing
    exit 1
fi

echo mounting $TREKDIR
mount $TREKDIR
if [ ! -e $TREKDIR/this_is_trekstoooor ] ; then
    umount $TREKDIR
    echo wrong USB device at $TREKDIR
    exit 1
fi

if [ ! -d $LOCALDIR ] ; then
    echo local directory $LOCALDIR missing
    exit 1
fi

### do the work

echo syncing $TREKDIR to $LOCALDIR
echo

rsync \
    --verbose \
    --recursive \
    --copy-links \
    --whole-file \
    --ignore-existing \
    --delete \
    --size-only \
    --progress \
    $LOCALDIR/ \
    $TREKDIR/

echo

### cleanup

df -h $TREKDIR
echo umounting $TREKDIR
umount $TREKDIR
echo OK.
