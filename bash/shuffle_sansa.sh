#!/bin/bash
# shuffle SANSA mp3 stick

set -e

MOUNT=/mnt/usb_part
DIR=_random

## setup

MOUNTED=no
if mount | grep -q $MOUNT ; then
    MOUNTED=yes
else
    echo -e mount...
    mount $MOUNT
    echo OK
fi


## do the work

if [ -d $MOUNT/$DIR ] ; then
    echo -e shuffle...
    sansafill.pl --shuffle $MOUNT/$DIR
    echo OK
else
    echo $MOUNT/$DIR not found, skipping
fi


## teardown

if [ $MOUNTED = 'no' ] ; then
    echo -e umount...
    umount $MOUNT
    echo OK
fi
