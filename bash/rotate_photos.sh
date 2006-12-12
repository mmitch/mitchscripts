#!/bin/bash
# $Id: rotate_photos.sh,v 1.2 2006-12-12 19:13:14 mitch Exp $

set_bg()
{
    chbg -once -mode smart -max_grow 100 -max_size 100 -scenario /home/mitch/download/xxx/pic/SORT/NAMED/.scenario $1
}

rotate()
{
    (
	jpegtran-mmx -copy all -rotate $1 -outfile NEW $FILE
	touch -r $FILE NEW
	mv NEW $FILE
    ) &
}

FONT="-misc-fixed-medium-r-*-*-13-*-*-*-*-*-*-*"
NORMBG="#004000"
NORMFG="#00B000"
SELBG="#006000"
SELFG="#00DF00"

CONVERT="jpegtran-mmx"

cat > .choices <<EOF
1 none
2 counterclockwise 90°
3 180°
4 clockwise 90°
5 again
9 quit
EOF

NEXT=1
for FILE in imgp????.jpg; do

    while [ $NEXT = 1 ]; do
    
	set_bg $FILE
	NEXT=1

	ANSWER=$(dmenu -font "$FONT" -normbg $NORMBG -normfg $NORMFG -selbg $SELBG -selfg $SELFG < .choices)
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
		break
		;;
	esac

    done

done

killall -USR1 chbg
