#!/bin/bash
#
# simple X notification framework
# process procmail mail logs and convert them to notify entries
#
# Copyright (C) 2009-2010,2014,2016  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#

tail -n 1 -f ~/Mail/from | ~/git/mitchscripts/perl/mimedecoder.pl | while read LINE; do

    if [[ "$LINE" =~ ^From ]] ; then
	FROM="${LINE:5}"
	FROM="${FROM%% *}"

	read SUBJECT
	SUBJECT="${SUBJECT:9}"
	
	read FOLDER
	FOLDER="${FOLDER:8}"
	FOLDER="${FOLDER%/new/*}"
	FOLDER="${FOLDER#/home/mitch/Mail/}"

	if [[ ! "${FOLDER}" =~ (spam|null|warpzone-ml|receive-report.sh) ]] ; then
	    echo "%%   $FOLDER   %%   $FROM   %%   $SUBJECT" >> ~/.notify
	fi
    fi

done
