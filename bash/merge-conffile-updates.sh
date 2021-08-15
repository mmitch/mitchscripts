#!/bin/bash
#
# Merge conffile updates after a Debian release update.
#
# Copyright (C) 2021  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later


# DESCRIPTION and WARNINGS
# ========================
#
# Just do your release update as usual. You will be asked how to
# handle conffile updates.  This script is intended for to just press
# Enter and that prompt and sort out the upgrade conflicts later.  Be
# aware that YOU MIGHT RUN INTO PROBLEMS by doing this when eg.  the
# old sshd configuration is incompatible with a new sshd version, sshd
# won't start after the package update and you can't log in.  So far,
# I've never had any problems.  The Debian bullseye Release Notes
# advise to install the new maintainer versions, but this might also
# run into problems when you thus overwrite some required local
# configuration.
#
# In the end it does not matter if you choose 'keep current version'
# or 'install new maintainer version' during the package updates,
# running this script will pick up both '*.dpkg-new' and '*.dpkg-old'
# (same with ucf).
#
# All conffiles matching *.dpkg-* and *.ucf-* are offered for a merge.
# After a merge, the 'other' conffile (*.dpkg-* or *.ucf-*) will be
# DELETED from /etc.
#
# You can use etckeeper to have a backup of /etc, but please note that
# you have to manually reconfigure etckeeper to not ignore *.dpkg-*
# and *.ucf-*.  By default they are NOT included in your git history.
#
# Intermediate files (version 1, version 2, merged file or removed
# files) of all conffiles are created in a temporary subdirectory and
# KEPT there when this script ends.  These files will NOT be
# automatically deleted when all conffiles have been processed or the
# script has been interrupted.  You can use the files to see what you
# have recently done.
#
# Because the files reside in a /tmp-ish directory, they will probably
# vanish on the next boot, so BEWARE.


# REQUIREMENTS
# ============
#
# - `whiptail` for file selection and other dialogs
# - `emacs` for merging the files
#   (this can be easily changed to another tool or editor,
#    see two_way_merge())
# - `tput` to get terminal size
#   (optional; 60x18 will be used if not present)


# TODO
# ====
#
# - find a proper name for conffiles like *.dpkg-* and *.ucf-*
#   - rename $conffile to that new name
#   - rename $basefile to $conffile
# - recreate the directory structore for intermediate files?
# - support three-way-merges?
#   is there a way to get the pristine conffile from the previous release?
# - set -e
# - run ShellCheck
# - rewrite in a proper language


#--------------------------------------------------------------------------------
# SUBS

action_completed()
{
    local file=$1 action=$2
    
    action_id=$(( action_id + 1 ))

    local cols=$(tput cols  2>&1 || echo 60)

    whiptail --title "$file OK" --msgbox "$file $action" 10 $(( cols - 4 ))
}

action_aborted()
{
    local file=$1 action=$2
    
    local cols=$(tput cols  2>&1 || echo 60)

    whiptail --title "ABORT: $file" --msgbox "$file $action" 10 $(( cols - 4 ))
}

is_deleted()
{
    local file=$1

    [[ $file =~ \.dpkg-removed$ ]]
}

is_new()
{
    local file=$1

    [[ $file =~ \.dpkg-dist$ ]]
}

temp_filename()
{
    local source=$(basename "$1")
    local action=${2:-unknown}

    printf '%s/%04d.%s..%s' "$tempdir" "$action_id" "$source" "$action"
}

init_tempfiles()
{
    action_id=0
    tempdir=$( mktemp --directory --tmpdir merge-conffile-updates.XXXXXXXXXX )

    trap 'echo intermediate files in "<$tempdir>" are kept' EXIT
}

record_path()
{
    local file=$1

    echo "$file" > "$( temp_filename "$file" path )"
}

two_way_merge()
{
    local file1="$1" file2="$2" output="$3"

    emacs --eval "(progn (setq ediff-quit-hook 'kill-emacs) (ediff-merge-files \"$input1\" \"$input2\" nil \"$output\"))"
}

remove()
{
    local conffile=$1

    record_path "$conffile"
    mv "$conffile" "$( temp_filename "$conffile" removed )"
    action_completed "$conffile" 'has been removed'
}

add()
{
    local basefile=$1
    local conffile=$2

    record_path "$conffile"
    cp "$conffile" "$( temp_filename "$basefile" added )"
    mv "$conffile" "$basefile"
    action_completed "$conffile" 'has been added and renamed to "$basefile"'
}

list()
{
    local file="$1"

    ${PAGER:-less} "$file"
}

handle_merge()
{
    local basefile=$1
    local conffile=$2

    local input1="$( temp_filename "$basefile" input )"
    local input2="$( temp_filename "$conffile" input )"
    local output="$( temp_filename "$basefile" output )"

    cp "$basefile" "$input1"
    cp "$conffile" "$input2"
    touch "$output"
    
    if two_way_merge "$input1" "$input2" "$output" && [ -s "$output" ]; then

	record_path "$basefile"
	rm "$conffile"
	cp "$output" "$basefile"
	action_completed "$basefile" "has been merged with $conffile"

    else

	rm "$input1" "$input2" "$output"
	action_aborted "$basefile" "not merged with $conffile"
	
    fi
}

handle_removal()
{
    local basefile=$1
    local conffile=$2

    local continue=yes
    while [ $continue = yes ]; do

	local cols=$(tput cols  2>&1 || echo 60)
	local rows=$(tput lines 2>&1 || echo 18)

	selection=$( whiptail --title "$conffile" --menu "No current file found, this looks like a removal: " 12 $(( cols - 4 )) 3 \
			      'L' 'ist file' \
			      'R' 'emove file' \
			      'C' 'ancel' \
			      3>&2 2>&1 1>&3- )

	if [ $? -ne 0 ] || [ $selection = C ]; then
	    action_aborted "$conffile" 'not removed'
	    continue=no
    
	elif [ $selection = R ]; then
	    remove "$conffile"
	    continue=no

	else
	    list "$conffile"
	fi

    done
}

handle_addition()
{
    local basefile=$1
    local conffile=$2

    local continue=yes
    while [ $continue = yes ]; do

	local cols=$(tput cols  2>&1 || echo 60)
	local rows=$(tput lines 2>&1 || echo 18)

	selection=$( whiptail --title "$conffile" --menu "No current file found, this looks like an addition: " 12 $(( cols - 4 )) 3 \
			      'L' 'ist file' \
			      'A' 'add file' \
			      'C' 'ancel' \
			      3>&2 2>&1 1>&3- )

	if [ $? -ne 0 ] || [ $selection = C ]; then
	    action_aborted "$conffile" 'not added'
	    continue=no

	elif [ $selection = R ]; then
	    add "$basefile" "$conffile"
	    continue=no

	else
	    list "$conffile"
	fi

    done
}

handle_unknown_single_file()
{
    local conffile=$1

    abort_command "$conffile" "unknown single file $conffile encountered, don't know what to do"
}

handle_conffile()
{
    local basefile=${1%.*}
    local conffile=$1

    if [ -e "$basefile" ]; then
	handle_merge "$basefile" "$conffile"

    else
	if is_deleted "$conffile"; then
	    handle_removal "$basefile" "$conffile"

	elif is_new "$conffile"; then
	    handle_addition "$basefile" "$conffile"

	else
	    handle_unknown_single_file "$conffile"

	fi
    fi
}

find_candidates_0()
{
    {
	find /etc -name '*.dpkg-*' -print0 
	find /etc -name '*.ucf-*'  -print0 
    } | sort -z
}

get_conffiles() {
    conffiles=()
    mapfile -d '' -t conffiles < <(find_candidates_0)
}

select_conffile() {
    whiptail_args=()

    local cols=$(tput cols  2>&1 || echo 60)
    local rows=$(tput lines 2>&1 || echo 18)

    local entries=()
    local conffile
    # todo: unique tags: letters [a..z ,aa..zz , ...] or filenames
    tag=0
    for conffile in "${conffiles[@]}"; do
	entries+=($tag "$conffile")
	tag=$(( tag + 1 ))
    done
    
    selection=$( whiptail --menu "Select conffile to merge:" $(( rows - 2 )) $(( cols - 4 )) $(( rows - 10 )) "${entries[@]}" 3>&2 2>&1 1>&3- )
    if [ $? -ne 0 ]; then
	echo "conffile selection canceled"
	exit 0
    fi
}


#--------------------------------------------------------------------------------
# MAIN SCRIPT TURN ON

init_tempfiles

while true; do
    
    get_conffiles

    if [ ${#conffiles[@]} -eq 0 ]; then
	echo "no conffiles need merge"
	echo "finished"
	exit 0
    fi

    select_conffile

    handle_conffile "${conffiles[$selection]}"

done
