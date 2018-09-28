#!/bin/bash

# concatenate and reencode videos with FFMPEG
#
# Copyright (C) 2018  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#

# parameters:
# $1: target file
# $*: source files

# for details see https://trac.ffmpeg.org/wiki/Concatenate

set -e

TARGET="$1"
shift

CONCAT=
INPUT=
COUNT=0
for SOURCE in "$@"; do
    CONCAT="$CONCAT[$COUNT:v:0][$COUNT:a:0]"
    INPUT="$INPUT -i \"$SOURCE\""
    COUNT=$(( COUNT + 1 ))
done

CONCAT="${CONCAT}concat=n=$COUNT:v=1:a=1[outv][outa]"

COMMANDLINE="ffmpeg $INPUT -filter_complex \"$CONCAT\" -map \"[outv]\" -map \"[outa]\" \"$TARGET\""

echo $COMMANDLINE
eval "$COMMANDLINE"
