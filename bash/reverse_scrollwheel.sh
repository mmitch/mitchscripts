#!/bin/bash
#
# swap mouse wheel scrolling like OSX Lion
#
# Copyright (C) 2011  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
# based on an idea taken from:
# http://n00bsys0p.wordpress.com/2011/07/26/reverse-xorg-scrolling-in-linux-natural-scrolling/

ID=$( xinput list | egrep 'slave.*pointer' | grep -i mouse | sed -e 's/^.*id=//' -e 's/\s.*$//' )

BUTTONS=( $( xinput get-button-map $ID ) )

TEMP=${BUTTONS[3]}
BUTTONS[3]=${BUTTONS[4]}
BUTTONS[4]=$TEMP

xinput set-button-map $ID ${BUTTONS[*]}

