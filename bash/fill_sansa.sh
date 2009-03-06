#!/bin/bash
# fill SANSA mp3 stick

set -e

SRC="${1}"
MOUNT=/mnt/usb_part
DIR=_random
FREE=48000
DUPES=/tmp/sansa_script_fdupes

count_dupes()
{
    echo -n checkdupes...
    fdupes -q -f $MOUNT/$DIR > $DUPES || yes
    echo OK
    DUPECOUNT=$(wc -l $DUPES | cut -d \  -f 1)
}

## choose source directory

if [ ! "$SRC" ] ; then

    DIR=/mnt/mp3/SANSA_STAGE
    DEFAULT="$DIR"/KWED
    ITEMS[0]="$DEFAULT"
    ITEMS[1]=''

    for FILE in "$DIR"/* ; do
	[ -d "$FILE" ] || continue
	[ "$FILE" = "$DEFAULT" ] && continue
        ITEMS[${#ITEMS[*]}]="$FILE"
        ITEMS[${#ITEMS[*]}]=''
    done

    SRC="$(dialog --stdout --menu "choose source directory" 0 0 0 "${ITEMS[@]}")"
    
    [ "$SRC" ] || exit 1
fi


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
