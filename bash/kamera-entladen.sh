#!/bin/bash
# $Id: kamera-entladen.sh,v 1.1 2007-01-01 17:27:15 mitch Exp $
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

mv $PICPATH/* $SAVEPATH

echo finished

sync
umount $USBPATH
eject $USBPATH

echo unmounted
