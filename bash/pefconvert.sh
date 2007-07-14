#!/bin/bash
# $Id: pefconvert.sh,v 1.1 2007-07-14 21:19:10 mitch Exp $
#
# mass convert Pentax RAWs (.pef) to jpeg/tiff/tiff16
#
# 2007 (c) by Christian Garbs <mitch@cgarbs.de>
# licensed under the GNU GPL v2 and no later versions
#
# needs
# - backgrounder.pl from www.cgarbs.de
# - dcraw
# - convert from imagemagick

# default values
FORMAT=1

# commandline handling
if [ "$1" = '-h' ] ; then
    cat <<EOF
pefconvert.sh [-h|-j|-t|-T]
 -h  help
 -j  convert to JPEG (default)
 -t  convert to 8bit TIFF
 -T  convert to 16bit TIFF
EOF
    exit 0
fi

[ "$1" = '-j' ] && FORMAT=1
[ "$1" = '-t' ] && FORMAT=2
[ "$1" = '-T' ] && FORMAT=3

# run how many parallel conversions?
CPUS=$(grep ^processor /proc/cpuinfo | wc -l)

# read all files
for FILE in *.pef; do
    FLIP=0
    if [ -e "$FILE.rotation" ] ; then
	case $(< "$FILE.rotation") in
	    180)  FLIP=3 ;;
	     90)  FLIP=6 ;;
	    270)  FLIP=5 ;;
	esac
    fi
    
    case $FORMAT in

	1)
	    echo -n "dcraw -c -w -q 3 -t $FLIP \"$FILE\" | convert -quality 90 - \"${FILE%.pef}.jpg\""
	    echo "&& touch -r \"$FILE\" \"${FILE%.pef}.jpg\""
	    ;;

	2)
	    echo -n "dcraw -c -w -q 3 -t $FLIP \"$FILE\" | convert -compress LZW - \"${FILE%.pef}.tiff\""
	    echo "&& touch -r \"$FILE\" \"${FILE%.pef}.tiff\""
	    ;;

	3)
	    echo -n "dcraw -c -w -q 3 -t $FLIP -4 -T \"$FILE\" | convert -compress LZW - \"${FILE%.pef}.tiff\""
	    echo "&& touch -r \"$FILE\" \"${FILE%.pef}.tiff\""
	    ;;

    esac
	
done
# | backgrounder.pl $CPUS -
