#!/bin/bash
#
# rotate_photos.sh - simple picture preview and rotating tool
# Copyright (C) 2006-2008,2013 Christian Garbs <mitch@cgarbs.de>
# Licensed under the GNU GPL v3 or later

# check for stuff we need
CHECK_FOR()
{
    if [ ! -x "$(which $1)" ] ; then
	echo "binary \`$1' needed, but not found" 1>&2
	exit 1
    fi
}
CHECK_FOR feh
CHECK_FOR jpegtran
CHECK_FOR dmenu

set -e

set_bg()
{
   feh --no-fehbg --bg-fill "$1"
}

rotate()
{
    (
	TMP=NEW.$$
	jpegtran -trim -copy all -rotate "$1" -outfile $TMP "$FILE"
	touch -r "$FILE" $TMP
	mv $TMP "$FILE"
	# check for thumbnails of RAW images
	RAW="${FILE//_thumb.jpg/}"
	if [ -e "${RAW}.pef" ] ; then
	    ROTATEFILE="${RAW}.pef.rotation"
	    OLDROTATE=0
	    [ -e "$ROTATEFILE" ] && OLDROTATE=$(< "$ROTATEFILE") && rm "$ROTATEFILE"
	    NEWROTATE=$(( $OLDROTATE + $1 ))
	    [ $NEWROTATE != 0 ] && echo $NEWROTATE > "$ROTATEFILE"
	fi
    ) &
}

FONT="-misc-fixed-medium-r-*-*-13-*-*-*-*-*-*-*"
NORMBG="#004000"
NORMFG="#00B000"
SELBG="#006000"
SELFG="#00DF00"

CHOICES=/tmp/rotate_photos.choices

pidof floatbg && killall floatbg

cat > "${CHOICES}" <<EOF
1 none
2 counterclockwise 90°
3 180°
4 clockwise 90°
5 again
6 back
9 quit
EOF

QUIT=0
declare -a FILES
for FILE in *.jpg *.JPG; do
    FILES+=($FILE)
done

CURRENT=0
NEXT=0

while [ "$QUIT" = 0 ] ; do

    CURRENT=$(( $CURRENT + $NEXT ))

    [ ${CURRENT} -gt ${#FILES[*]} ] && break
    [ ${CURRENT} -lt 0 ] && break

    FILE="${FILES[${CURRENT}]}"
    NEXT=1

    [ -r "$FILE" ] || continue

    set_bg "$FILE"

    ANSWER=$(dmenu -fn "$FONT" -nb $NORMBG -nf $NORMFG -sb $SELBG -sf $SELFG < "${CHOICES}")
    case "$ANSWER" in
	
	1*)
	    ;;
	
	2*)
	    rotate 270
	    ;;
	
	3*)
	    rotate 180
	    ;;
	
	4*)
	    rotate 90
	    ;;
	
	5*)
	    NEXT=0
	    ;;
	6*)
	    NEXT=-1
	    ;;
	9*)
	    QUIT=1
	    ;;
	*)
	    NEXT=0
	    sleep 5
	    ;;
    esac

done

killall -USR1 chbg
rm -f "${CHOICES}"
