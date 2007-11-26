#!/bin/bash
# $Id: rotate_photos.sh,v 1.14 2007-09-16 16:23:18 mitch Exp $

# check for stuff we need
CHECK_FOR()
{
    if [ ! -x "$(which $1)" ] ; then
	echo "binary \`$1' needed, but not found" 1>&2
	exit 1
    fi
}
CHECK_FOR chbg
CHECK_FOR jpegtran
CHECK_FOR dmenu

set -e

set_bg()
{
    chbg -once -mode smart -max_grow 100 -max_size 100 -scenario /home/mitch/download/xxx/pic/SORT/NAMED/.scenario "$1"
}

rotate()
{
    (
	TMP=NEW.$$
	jpegtran -copy all -rotate "$1" -outfile $TMP "$FILE"
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
9 quit
EOF

QUIT=0
for FILE in *.jpg *.JPG; do

    [ -r "$FILE" ] || continue

    NEXT=0
    while [ $NEXT = 0 ]; do
    
	set_bg "$FILE"
	NEXT=1

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
	    9*)
		QUIT=1
		;;
	    *)
		NEXT=0
		sleep 5
		;;
	esac

    done

    if [ $QUIT = 1 ] ; then
	break
    fi

done

killall -USR1 chbg
rm -f "${CHOICES}"
