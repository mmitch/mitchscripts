#!/bin/bash
#
# simple X notification framework
# process procmail mail logs and convert them to notify entries
#
# 2009 (C) by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2
#

tail -f ~/Mail/from | while read LINE; do

    if [[ "$LINE" =~ ^From ]] ; then
	FROM="${LINE:5}"
	FROM="${FROM%% *}"

	read SUBJECT
	SUBJECT="${SUBJECT:9}"
	
	read FOLDER
	FOLDER="${FOLDER:8}"
	FOLDER="${FOLDER%/new/*}"
	FOLDER="${FOLDER#/home/mitch/Mail/}"

	if [ "$FOLDER" != 'spam' ] ; then
	    echo "$FOLDER   %%   $FROM   %%   $SUBJECT" >> ~/.notify
	fi
    fi

done
