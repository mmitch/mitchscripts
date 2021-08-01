#!/bin/sh
#
# convert GIMP palette file to SVG image
#
# Copyright (C) 2021  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#

size=32

if [ "$1" ]; then
    exec < "$1"
fi

while read -r line; do
    [ "$line" = '#' ] && break
done

x=0
y=0
cat <<EOF
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg">
EOF
while read -r r g b _; do
    printf '  <rect x="%d" y="%d" width="%d" height="%d" style="fill:rgb(%d,%d,%d);" />\n' $x $y $size $size "$r" "$g" "$b"
    x=$(( x + size ))
done
echo '</svg>'
