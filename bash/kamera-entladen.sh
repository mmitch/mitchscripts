#!/bin/bash
# $Id: kamera-entladen.sh,v 1.14 2007-10-21 16:33:31 mitch Exp $

set -e

if [ "$1" == '-h' ] ; then
    cat <<'EOF'
kamera-entladen.sh [-h] [mountpoint target]
  -h  prints this help

version $Id: kamera-entladen.sh,v 1.14 2007-10-21 16:33:31 mitch Exp $
EOF
    exit 0;
fi

USBPATH=/mnt/pentax
SAVE=/mnt/bilder/Fotos/more/upload_$(date +%Y%m%d)

if [ "$1" -a "$2" ] ; then
    USBPATH="$1"
    SAVE="$2"
fi

PICPATH=$USBPATH/dcim/100pentx


# check for stuff we need
CHECK_FOR()
{
    if [ ! -x "$(which $1)" ] ; then
        echo "binary \`$1' needed, but not found" 1>&2
        exit 1
    fi
}
CHECK_FOR dcraw
CHECK_FOR exiftool


SAVEPATH=$SAVE
COUNT=
while [ -e $SAVEPATH ] ; do
    rmdir $SAVEPATH 2>/dev/null && break
    COUNT=$(( $COUNT + 1 ))
    SAVEPATH=${SAVE}_$(printf %02d $COUNT)
done
mkdir $SAVEPATH

echo saving at $SAVEPATH
mount | grep " on $USBPATH " >/dev/null || mount $USBPATH 

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
	    wait
	    (
		cd $SAVEPATH/
		FILENAME=${FILENAME%%.pef}
		dcraw -q 0 -h -c -T $FILENAME.pef | convert -scale 50% - ${FILENAME}_thumb.jpg
		exiftool -q -overwrite_original -TagsFromFile $FILENAME.pef -PreviewImage= -ThumbnailImage= -makernotes:all= ${FILENAME}_thumb.jpg
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
