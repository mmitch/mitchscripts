#!/bin/bash
# fill SANSA mp3 stick

set -e

SRC="${1}"
MOUNT=/mnt/usb_part
STICKDIR=_random
FREE=48000
TMPFILE=/tmp/sansa_script_fdupes
BACKTITLE='--backtitle fill_sansa.sh'

count_dupes()
{
    echo -n checkdupes...
    fdupes -q -f $MOUNT/$STICKDIR > $TMPFILE || true
    echo OK
    DUPECOUNT=$(wc -l $TMPFILE | cut -d \  -f 1)
}

## print help text

if [ "$SRC" = '-h' ] ; then
    cat <<EOF
usage:
  fill_sansa.sh [-h] [<src_dir>]

  -h         print help text
  <src_dir>  source path (default: ask)
EOF
    exit 1
fi

## choose removal of old files

if dialog $BACKTITLE --yesno "erase old files?" 0 0 ; then
    REMOVE=yes
else
    REMOVE=no
fi

## choose free space

if dialog $BACKTITLE --stdout --inputbox "free space [kB]" 0 0 $FREE > $TMPFILE ; then
    read FREE < $TMPFILE || true
fi

## choose source directory

if [ ! "$SRC" ] ; then

    DIR=/mnt/mp3/SANSA_STAGE
    DEFAULT="$DIR"/good
    ITEMS[0]="$DEFAULT"
    ITEMS[1]=''

    for FILE in "$DIR"/* "$DIR"/good/* ; do
	[ -d "$FILE" ] || continue
	[ "$FILE" = "$DEFAULT" ] && continue
        ITEMS[${#ITEMS[*]}]="$FILE"
        ITEMS[${#ITEMS[*]}]=''
    done

    SRC="$(dialog $BACKTITLE --stdout --menu "choose source directory" 0 0 0 "${ITEMS[@]}")"
    
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

if [ -d $MOUNT/$STICKDIR ] ; then
    if [ $REMOVE = 'yes' ] ; then
	if [ $( ls $MOUNT/$STICKDIR/ | wc -l ) -gt 0 ] ; then
	    echo removing old files
	    rm  $MOUNT/$STICKDIR/*
	fi
    fi
    echo source dir: $SRC
    sansafill.pl --fill "$SRC" $MOUNT/$STICKDIR $FREE
    count_dupes
    while [ $DUPECOUNT -gt 0 ] ; do
	echo $DUPECOUNT dupes
	while read FILE ; do
	    if [ "$FILE" ]; then
		rm "$FILE"
	    fi
	done < $TMPFILE
	sansafill.pl --fill "$SRC" $MOUNT/$STICKDIR $FREE
	count_dupes
    done
else
    echo $MOUNT/$STICKDIR not found, skipping
fi


## teardown

if [ $MOUNTED = 'no' ] ; then
    echo -e umount...
    umount $MOUNT
    echo OK
fi
