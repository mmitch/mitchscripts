#!/bin/bash
# $Id: kamera-entladen.sh,v 1.5 2007-03-25 17:58:32 mitch Exp $

set -e

USBPATH=/mnt/usb_part
PICPATH=$USBPATH/dcim/100pentx
SAVE=/mnt/bilder/Fotos/more/upload_$(date +%Y%m%d)

SAVEPATH=$SAVE
COUNT=
while [ -e $SAVEPATH ] ; do
    COUNT=$(( $COUNT + 1 ))
    SAVEPATH=${SAVE}_$(printf %02d $COUNT)
done
mkdir $SAVEPATH

echo saving at $SAVEPATH
mount $USBPATH

PICCOUNT=$(find $PICPATH -type f | wc -l)
if [ $PICCOUNT -ge 1 ] ; then
    echo "$PICCOUNT pictures to copy"
    mv -v $PICPATH/* $SAVEPATH | fgrep --line-buffered -- '->' | (
	COUNT=0
	while read FILE; do
	    if [ $(( $COUNT % 5 )) = 0 ]; then
		echo $COUNT
	    else
		echo "."
	    fi
	    COUNT=$(( $COUNT + 1 ))
	done
	echo
    )
else
    echo "nothing to copy"
    rmdir $SAVEPATH
fi

echo finished

sync
umount $USBPATH
eject $USBPATH || true

echo unmounted
