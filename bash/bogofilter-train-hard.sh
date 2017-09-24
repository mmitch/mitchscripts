#!/bin/bash
#
# repeated bogofilter training until it sticks!
# fed with a single mail via stdin
# no output (except for errors/status)

##### setup

set -e

# set up temporary file
MAIL="$(mktemp -t bogo-train-hard.XXXXXXXX)"

# capture stdin
cat > "$MAIL"

on_exit()
{
    # remove tempfile
    rm "$MAIL"
}

trap on_exit EXIT

##### subroutines

abend() {
    echo "${@}" 1>&2
    exit 1
}

##### main

if [ "$1" = '--this-is-spam' ]; then
    UNTIL=S
    TRAIN=-Ns
elif [ "$1" = '--this-is-ham' ]; then
    UNTIL=H
    TRAIN=-Sn
else
    abend "usage: $0 [ --this-is-spam | --this-is-ham ]"
fi

if [ ! -s "$MAIL" ]; then
    abend 'input is empty'
fi

COUNT=0
while true; do
    # check bogofilter status
    read TYPE SCORE <<< $(bogofilter -e -T -I "$MAIL")
    echo "$TYPE $SCORE"

    # break if training completed
    if [ "$TYPE" = "$UNTIL" ]; then
	break
    fi

    # break if endless loop
    if [ $COUNT -eq 25 ]; then
	abend "looping!"
    fi
    COUNT=$(( COUNT + 1 ))

    # train bogofilter
    bogofilter $TRAIN -I "$MAIL"
done
