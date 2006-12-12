#!/bin/bash
# $Id: rotate_photos.sh,v 1.1 2006-12-12 19:04:47 mitch Exp $

set_bg()
{
    chbg -once -mode smart -max_grow 100 -max_size 100 -scenario /home/mitch/download/xxx/pic/SORT/NAMED/.scenario $1
}

rotate()
{
    (
	jpegtran-mmx -rotate $1 -outfile NEW $FILE
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
5 quit
EOF

for FILE in imgp????.jpg; do

    set_bg $FILE
    
    ANSWER=$(dmenu -font "$FONT" -normbg $NORMBG -normfg $NORMFG -selbg $SELBG -selfg $SELFG < .choices)
    echo $ANSWER
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
	    break
	    ;;
    esac

done

killall -USR1 chbg
