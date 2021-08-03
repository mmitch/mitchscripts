#!/bin/bash
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

# read color lines into memory
mapfile palette
palette_length=${#palette[@]}

# calculate smalles square to fit palette entries
square_size=1
squared_size=1
while [ $squared_size -lt "$palette_length" ]; do
    square_size=$(( square_size + 1 ))
    squared_size=$(( square_size * square_size ))
done

# expand palette to full square
while [ "$palette_length" -lt $squared_size ]; do
    palette+=( "0 0 0 empty" )
    palette_length=$(( palette_length + 1 ))
done

# print SVG header
width=$(( square_size * size ))
height=$width
printf '<?xml version="1.0"?>\n'
printf '<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="%dpx" height="%dpx">\n' $width $height

i=0
x=0
y=0
while [ $i -lt $palette_length ]; do
    # parse palette line
    read -r r g b _ <<< "${palette[$i]}"

    # print palette box
    printf '  <rect x="%dpx" y="%dpx" width="%dpx" height="%dpx" style="fill:rgb(%d,%d,%d);" />\n' $x $y $size $size "$r" "$g" "$b"

    # calculate next entry
    i=$(( i + 1 ))
    x=$(( x + size ))
    if [ $x -eq $width ]; then
	x=0
	y=$(( y + size ))
    fi
done

# print SVG footer
echo '</svg>'

# print image size
printf '%dx%d' $width $height >&2
