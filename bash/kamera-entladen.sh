#!/bin/bash
#
# Copyright (C) 2007,2008,2010  Christian Garbs <mitch@cgarbs.de>
# licensed under the GNU GPL v2 and no later versions

set -e

if [ "$1" == '-h' ] ; then
    cat <<'EOF'
kamera-entladen.sh [-h|-t] [mountpoint target]
  -h  prints this help
  -t  generate thumbnails
EOF
    exit 0;
fi

if [ "$1" == '-t' ] ; then
    THUMBNAILS=yes
else
    THUMBNAILS=no
fi

USBPATH=/mnt/pentax
SAVE=/mnt/bilder/Fotos/more/upload_$(date +%Y%m%d)

if [ "$1" -a "$2" ] ; then
    USBPATH="${1%/}"
    SAVE="${2%/}"
fi


# check for stuff we need
CHECK_FOR()
{
    if [ ! -x "$(which $1)" ] ; then
        echo "binary \`$1' needed, but not found" 1>&2
        exit 1
    fi
}
[ $THUMBNAILS = yes ] && CHECK_FOR dcraw
[ $THUMBNAILS = yes ] && CHECK_FOR exiftool

# always clean up possible empty path
remove_empty_savepath()
{
    rmdir "$SAVEPATH" 2>/dev/null || true
}

SAVEPATH="$SAVE"
COUNT=
while [ -e "$SAVEPATH" ] ; do
    COUNT=$(( $COUNT + 1 ))
    SAVEPATH="${SAVE}_$(printf %02d $COUNT)"
done
mkdir "$SAVEPATH"
trap remove_empty_savepath EXIT


echo saving at $SAVEPATH
mount | grep " on $USBPATH " >/dev/null || mount $USBPATH || gphotofs $USBPATH

PICPATH=$USBPATH/dcim/
[ ! -d $PICPATH ] && PICPATH=$USBPATH/DCIM/
[ ! -d $PICPATH ] && PICPATH=$USBPATH/store_*/dcim/
[ ! -d $PICPATH ] && PICPATH=$USBPATH/store_*/DCIM/

PICCOUNT=$(find $PICPATH -type f | wc -l)
if [ $PICCOUNT -ge 1 ] ; then
    echo "$PICCOUNT pictures to copy"
    COUNT=0
    find $PICPATH -type f | while read FILE; do
	FILENAME=$(echo ${FILE##*/}|tr A-Z a-z)
	mv -i $FILE "$SAVEPATH/$FILENAME"
	chmod -x "$SAVEPATH/$FILENAME"
	if [ $(( $COUNT % 5 )) = 0 ]; then
	    echo -n $COUNT
	else
	    echo -n "."
	fi
	COUNT=$(( $COUNT + 1 ))

	# autogenerate thumbnails from RAWs

	if [[ ( "$THUMBNAILS" = 'yes' ) && ( "$FILENAME" == *.pef) ]] ; then
	    wait
	    (
		cd "$SAVEPATH/"
		FILENAME=${FILENAME%%.pef}
		dcraw -q 0 -h -c -T $FILENAME.pef | convert -scale 50% - ${FILENAME}_thumb.jpg && \
		exiftool -q -overwrite_original -TagsFromFile $FILENAME.pef -PreviewImage= -ThumbnailImage= -makernotes:all= ${FILENAME}_thumb.jpg
	    ) &
	fi

	if [[ ( "$THUMBNAILS" = 'yes' ) && ( "$FILENAME" == *.cr2) ]] ; then
	    wait
	    (
		cd "$SAVEPATH/"
		FILENAME=${FILENAME%%.cr2}
		dcraw -q 0 -h -c -T $FILENAME.cr2 | convert -scale 50% - ${FILENAME}_thumb.jpg && \
		exiftool -q -overwrite_original -TagsFromFile $FILENAME.cr2 -PreviewImage= -ThumbnailImage= -makernotes:all= ${FILENAME}_thumb.jpg
	    ) &
	fi

    done
    echo
else
    echo "nothing to copy"
fi

echo copied

sync
umount $USBPATH || pumount $USBPATH || fusermount -u $USBPATH
eject $USBPATH || true

echo unmounted

cat <<'EOF'
 _  __                              
| |/ /__ _ _ __ ___   ___ _ __ __ _ 
| ' // _` | '_ ` _ \ / _ \ '__/ _` |
| . \ (_| | | | | | |  __/ | | (_| |
|_|\_\__,_|_| |_| |_|\___|_|  \__,_|
                                    
                                      _                _ 
  __ _ _   _ ___ _ __ ___   __ _  ___| |__   ___ _ __ | |
 / _` | | | / __| '_ ` _ \ / _` |/ __| '_ \ / _ \ '_ \| |
| (_| | |_| \__ \ | | | | | (_| | (__| | | |  __/ | | |_|
 \__,_|\__,_|___/_| |_| |_|\__,_|\___|_| |_|\___|_| |_(_)

EOF

wait
echo finished
