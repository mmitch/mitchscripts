#!/bin/bash
# $Id: kamera-entladen.sh,v 1.7 2007-06-08 18:16:39 mitch Exp $

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
    COUNT=0
    for FILE in $PICPATH/* ; do
	mv $FILE $SAVEPATH/
	if [ $(( $COUNT % 5 )) = 0 ]; then
	    echo -n $COUNT
	else
	    echo -n "."
	fi
	COUNT=$(( $COUNT + 1 ))

	# autogenerate thumbnails from RAWs

	FILENAME=${FILE##*/}
	if [[ $FILENAME == *.pef ]] ; then
	    (
		cd $SAVEPATH/
		FILENAME=${FILENAME%%.pef}
		dcraw -q 0 -h -T $FILENAME.pef
		convert -scale 50% $FILENAME.tiff ${FILENAME}_thumb.jpg
		rm $FILENAME.tiff
	    ) &
	fi

    done
    echo
else
    echo "nothing to copy"
    rmdir $SAVEPATH
fi

echo copied

sync
umount $USBPATH
eject $USBPATH || true

echo unmounted

wait
echo finished