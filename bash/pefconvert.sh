#!/bin/bash
# $Id: pefconvert.sh,v 1.4 2007-08-11 15:47:34 mitch Exp $
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
 -a  convert for chromatic abberation error calculation,
     see http://hugin.sourceforge.net/tutorials/tca/en.shtml
EOF
    exit 0
fi

[ "$1" = '-j' ] && FORMAT=1
[ "$1" = '-t' ] && FORMAT=2
[ "$1" = '-T' ] && FORMAT=3
[ "$1" = '-a' ] && FORMAT=10

# check for stuff we need
CHECK_FOR()
{
    if [ ! -x "$(which $1)" ] ; then
        echo "binary \`$1' needed, but not found" 1>&2
        exit 1
    fi
}
CHECK_FOR backgrounder.pl
CHECK_FOR convert
CHECK_FOR dcraw
CHECK_FOR exiftool


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
	    NEWFILE="${FILE%.pef}.jpg"
	    echo -n " dcraw -c -w -q 3 -t $FLIP \"$FILE\" | convert -quality 90 - \"$NEWFILE\""
	    ;;

	2)
	    NEWFILE="${FILE%.pef}.tiff"
	    echo -n " dcraw -c -w -q 3 -t $FLIP \"$FILE\" | convert -compress LZW - \"$NEWFILE\" "
	    ;;

	3)
	    NEWFILE="${FILE%.pef}.tiff"
	    echo -n " dcraw -c -w -q 3 -t $FLIP -4 -T \"$FILE\" | convert -compress LZW - \"$NEWFILE\""
	    ;;

	10)
	    NEWFILE="${FILE%.pef}"
	    FLENGTH=$(exiftool "$FILE"  | grep -m 1 ^Focal\ Length | tr -cd 0-9.)
	    echo -n " dcraw -c -w -q 3 -t $FLIP \"$FILE\" > \"$NEWFILE.tmp\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel RG -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-B.tif\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel GB -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-R.tif\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel BR -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-G.tif\" "
	    echo    " && rm \"$NEWFILE.tmp\" "
	    ;;

    esac

    if [ $FORMAT -lt 10 ] ; then
	echo -n " && exiftool -q -overwrite_original -TagsFromFile \"$FILE\" -PreviewImage= -ThumbnailImage= -makernotes:all= \"$NEWFILE\""
	echo    " && touch -r \"$FILE\" \"$NEWFILE\""
    fi
	
done \
| backgrounder.pl $CPUS -
