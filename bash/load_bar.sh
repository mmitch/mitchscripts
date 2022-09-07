#!/bin/bash

LOAD_CHARS=' ▁▂▃▄▅▆▇█'
LOAD_BAR='                                              «'
load_bar()
{
    local load
    local load_idx

    load=$(cut -d ' ' -f 1 /proc/loadavg)
    case $load in
	0.[01]*)
	    load_idx=0
	    ;;

	0.[23]*)
	    load_idx=1
	    ;;

	0.[456]*)
	    load_idx=2
	    ;;

	0.*)
	    load_idx=3
	    ;;

	1*)
	    load_idx=4
	    ;;

	2*)
	    load_idx=5
	    ;;

	3*)
	    load_idx=6
	    ;;
	
	[45]*)
	    load_idx=7
	    ;;
	
	*)
	    load_idx=8
	    ;;
    esac

    LOAD_BAR="${LOAD_BAR:1}${LOAD_CHARS:$load_idx:1}"

    printf "\r%s" "$LOAD_BAR"
}

echo
while sleep 1; do
    load_bar;
done
