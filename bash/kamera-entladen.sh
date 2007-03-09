#!/bin/bash
# $Id: kamera-entladen.sh,v 1.3 2007-03-09 14:43:38 mitch Exp $

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
    mv -v $PICPATH/* $SAVEPATH | (
	COUNT=0
	while read FILE; do
	    if [ $(( $COUNT % 5 )) = 0 ]; then
		echo -n $COUNT
	    else
		echo -n "."
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
