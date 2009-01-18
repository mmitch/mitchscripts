#!/bin/bash
# fill SANSA mp3 stick

set -e

SRC="${1:-/mnt/mp3/SANSA_STAGE}"
MOUNT=/mnt/usb_part
DIR=_random
FREE=48000
DUPES=/tmp/sansa_script_fdupes

count_dupes()
{
    echo -n checkdupes...
    fdupes -q -f $MOUNT/$DIR > $DUPES
    echo OK
    DUPECOUNT=$(wc -l $DUPES | cut -d \  -f 1)
}

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
    echo source dir: $SRC
    sansafill.pl --fill "$SRC" $MOUNT/$DIR $FREE
    count_dupes
    while [ $DUPECOUNT -gt 0 ] ; do
	echo $DUPECOUNT dupes
	while read FILE ; do
	    if [ "$FILE" ]; then
		rm "$FILE"
	    fi
	done < $DUPES
	sansafill.pl --fill "$SRC" $MOUNT/$DIR $FREE
	count_dupes
    done
else
    echo $MOUNT/$DIR not found, skipping
fi


## teardown

if [ $MOUNTED = 'no' ] ; then
    echo -e umount...
    umount $MOUNT
    echo OK
fi
