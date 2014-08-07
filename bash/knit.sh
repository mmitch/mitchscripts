#!/bin/bash
#
# knit.sh -- take pixel art input image and process as knitting template
#
# Copyright 2014 (C)  Christian Garbs <mitch@cgarbs.de>
# Licensed under Gnu GPL v3 or later
#
# scale image according to the Maschenprobe and add a grid in the output image
# needs ImageMagick tools
#
# TODO: use commandline arguments instead of variable declarations in this script



##### CONFIGURATION START

# Maschenprobe: 10cm x 10cm sind x Maschen in y Reihen
MASCHEN=24
REIHEN=34

# filenames (output file is silently overwritten!)
IMAGE_IN=image.png
IMAGE_OUT=image.out.png

# value is arbitrarily chosen :)
TOTAL_SCALE=512

# number density in grid (also: thick lines)
GRIDTEXTMOD=5

##### CONFIGURATION END


# calculate scale factors
SCALE_X=$(( TOTAL_SCALE / MASCHEN ))
SCALE_Y=$(( TOTAL_SCALE / REIHEN ))

# get current image size
SIZE=$( identify -verbose "${IMAGE_IN}" | grep Geometry: | sed -e 's/^.*Geometry:\s*//' -e 's/\+.*$//' )
SIZE_X=${SIZE%%x*}
SIZE_Y=${SIZE##*x}
echo "image is $SIZE_X x $SIZE_Y pixels"

# calculate future image size (one extra pixel for final grid line)
NEW_X=$(( SIZE_X * SCALE_X + 1))
NEW_Y=$(( SIZE_Y * SCALE_Y + 1))
echo "image will be scaled to $NEW_X x $NEW_Y pixels"

# generate vertical line commands
for (( X=0 ; X <= NEW_X ; X=X + SCALE_X )) ; do
    DRAWSTR="${DRAWSTR} line $X,0 $X,$NEW_Y"
done

# generate horizontal line commands
for (( Y=0 ; Y <= NEW_Y ; Y=Y + SCALE_Y )) ; do
    DRAWSTR="${DRAWSTR} line 0,$Y $NEW_X,$Y"
done

# generate horizontal text commands
MASCHE=0
for (( X=0 ; X <= NEW_X ; X=X + SCALE_X )) ; do
    NR=$(( SIZE_X - MASCHE ))
    if [ $(( NR % GRIDTEXTMOD )) = 0 ] ; then
	TEXT="${TEXT} text $((X + 2)),$((NEW_Y - 2)) '$NR'"
	TEXT="${TEXT} text $((X + 2)),$((SCALE_Y - 2)) '$NR'"
	DRAWSTR="${DRAWSTR} line $((X + 1)),0 $((X + 1)),$NEW_Y"
    fi
    ((MASCHE++))
done

# generate vertical text commands
REIHE=-1
for (( Y=0 ; Y <= NEW_Y ; Y=Y + SCALE_Y )) ; do
    NR=$(( SIZE_Y - REIHE ))
    if [ $(( NR % GRIDTEXTMOD )) = 0 ] ; then
	TEXT="${TEXT} text 2,$((Y - 2)) '$NR'"
	TEXT="${TEXT} text $((NEW_X - SCALE_X + 1)),$((Y - 2)) '$NR'"
    fi
    if [ $(( NR % GRIDTEXTMOD )) = 1 ] ; then
	DRAWSTR="${DRAWSTR} line 0,$((Y + 1)) $NEW_X,$((Y + 1))"
    fi
    ((REIHE++))
done


# run convert and generate image
convert "${IMAGE_IN}" -scale "!${NEW_X}x${NEW_Y}" -draw "${DRAWSTR}" -font fixed -fill black -draw "${TEXT}" "${IMAGE_OUT}"
