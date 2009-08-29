#!/bin/bash

START=$(expr $(cat latest) + 1)
END=`lynx -dump www.ocremix.org |egrep remix/OCR |sed -e 's!.*OCR0\(.*\)/!\1!' |head -n 1`

for i in `seq $START $END`
do
    lynx -dump http://www.ocremix.org/remix/OCR0$i/ |
    egrep http://djpretzel.web.aplus.net.*mp3 |
    awk '{print $2}'
done | wget -ci -

echo $END > latest
