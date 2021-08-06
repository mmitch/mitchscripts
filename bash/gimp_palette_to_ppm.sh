#!/bin/bash
#
# convert GIMP palette file to PPM image
#
# Copyright (C) 2021  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#

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

# print PPM header
width=$square_size
height=$width
color_depth=256
printf 'P3\n%d %d\n%d\n' $width $height $color_depth
printf '# this is a PPM bitmap generated from GIMP palette\n'

i=0
x=0
y=0
while [ $i -lt $palette_length ]; do
    # parse palette line
    read -r r g b _ <<< "${palette[$i]}"

    # print palette pixel
    printf '%d %d %d' "$r" "$g" "$b"

    # calculate next entry
    i=$(( i + 1 ))
    x=$(( x + 1 ))
    if [ $x -eq $width ]; then
	x=0
	y=$(( y + 1 ))
	printf '\n'
    else
	printf ' '
    fi
done

# print image size
printf '%dx%d' $width $height >&2
