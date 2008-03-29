#!/bin/bash
#
# mass convert Pentax RAWs (.pef) to jpeg/tiff/tiff16
#
# 2007-2008 (c) by Christian Garbs <mitch@cgarbs.de>
# licensed under the GNU GPL v2 and no later versions
#
# needs
# - backgrounder.pl from http://www.cgarbs.de/backgrounder.en.html
# - dcraw           from http://www.cybercom.net/~dcoffin/dcraw/
# - convert         from http://www.imagemagick.org/
# - exiftool        from http://www.sno.phy.queensu.ca/~phil/exiftool/

# default values
FORMAT=1

# commandline handling
if [ "$1" = '-h' ] ; then
    cat <<EOF
pefconvert.sh [-h|-j|-t|-T] [image.pef] [...]
 -h  help
 -j  convert to JPEG (default)
 -J  convert to JPEG thumbnail
 -t  convert to 8bit TIFF
 -T  convert to 16bit TIFF
 -a  convert for chromatic abberation error calculation,
     see http://hugin.sourceforge.net/tutorials/tca/en.shtml
EOF
    exit 0
fi

[ "$1" = '-j' ] && FORMAT=1  && shift
[ "$1" = '-J' ] && FORMAT=2  && shift
[ "$1" = '-t' ] && FORMAT=3  && shift
[ "$1" = '-T' ] && FORMAT=4  && shift
[ "$1" = '-a' ] && FORMAT=10 && shift

FILES="${@}"
FILES="${FILES:=*.pef}"

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

# generate badpixels file
CREATE_BADPIXELS()
{
    cat <<EOF
# ~/.badpixels file for my Pentax *istDL
# dcraw will use this file if run in the same directory, or in any
# subdirectory.
# Always use "dcraw -d -j -t 0" when locating bad pixels!!
# Format is: pixel column, pixel row, UNIX time of death
# 2008/05/01
1023	587	1209592800
53	1187	1209592800
EOF
}


# run how many parallel conversions?
CPUS=$(grep ^processor /proc/cpuinfo | wc -l)

# backup old .badpixels if present
[ -e .badpixels ] && mv .badpixels .badpixels.$$
CREATE_BADPIXELS > .badpixels

# read all files
for FILE in $FILES; do

    if [ "$FILE" = '*.pef' ] ; then
	echo "no input files (*.pef) found" 1>&2
	exit 1
    fi

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
	    NEWFILE="${FILE%.pef}_thumb.jpg"
	    echo -n "dcraw -q 0 -h -c -T -t $FLIP \"$FILE\" | convert -scale 50% - \"$NEWFILE\""
	    ;;

	3)
	    NEWFILE="${FILE%.pef}.tiff"
	    echo -n " dcraw -c -w -q 3 -t $FLIP \"$FILE\" | convert -compress LZW - \"$NEWFILE\" "
	    ;;

	4)
	    NEWFILE="${FILE%.pef}.tiff"
	    echo -n " dcraw -c -w -q 3 -t $FLIP -4 -T \"$FILE\" | convert -compress LZW - \"$NEWFILE\""
	    ;;

	10)
	    NEWFILE="${FILE%.pef}"
	    FLENGTH=$(exiftool -FocalLength "$FILE" | tr -cd 0-9.)
	    echo -n " dcraw -c -w -q 3 \"$FILE\" > \"$NEWFILE.tmp\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel RG -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-B.tif\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel GB -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-R.tif\" "
	    echo -n " && convert \"$NEWFILE.tmp\" -channel BR -evaluate set 0 -compress LZW \"${NEWFILE}-${FLENGTH}-G.tif\" "
	    echo -n " && exiftool -overwrite_original \"-FocalLength=${FLENGTH}\" \"${NEWFILE}-${FLENGTH}-\"?.tif "
	    echo    " && rm \"$NEWFILE.tmp\" "

	    (
		echo 'p f2 w3032 h1819 v10  E1 R0 T n"TIFF c:NONE"'
		echo 'm g1 i0 f0 m2 p0.00784314'
		echo "i w3040 h2024 f0 Eb1 Eev1 Er1 Ra0 Rb0 Rc0 Rd0 Re0 Va1 Vb0 Vc0 Vd0 Vx0 Vy0 a0 b0 c0 d0 e0 g0 p0 r0 t0 v10.0 y0 Vm5 u10 n\"${NEWFILE}-${FLENGTH}-R.tif\""
		echo "i w3040 h2024 f0 Eb1 Eev0 Er1 Ra0 Rb0 Rc0 Rd0 Re0 Va1 Vb0 Vc0 Vd0 Vx0 Vy0 a0 b0 c0 d0 e0 g0 p0 r0 t0 v10.0 y0 Vm5 u10 n\"${NEWFILE}-${FLENGTH}-G.tif\""
		echo "i w3040 h2024 f0 Eb1 Eev0 Er1 Ra0 Rb0 Rc0 Rd0 Re0 Va1 Vb0 Vc0 Vd0 Vx0 Vy0 a0 b0 c0 d0 e0 g0 p0 r0 t0 v10.0 y0 Vm5 u10 n\"${NEWFILE}-${FLENGTH}-B.tif\""
		echo 'v c0 v0 '
		echo 'v c2 v2 '
		echo 'v '
) > "${NEWFILE}-${FLENGTH}".pto

	    ;;

    esac

    if [ $FORMAT -lt 10 ] ; then
	echo -n " && exiftool -q -overwrite_original -TagsFromFile \"$FILE\" -PreviewImage= -ThumbnailImage= -makernotes:all= \"$NEWFILE\""
	echo    " && touch -r \"$FILE\" \"$NEWFILE\""
    fi
	
done \
| backgrounder.pl $CPUS -

# restore old .badpixels
#rm -f .badpixels
#[ -e .badpixels.$$ ] && mv .badpixels.$$ .badpixels 
