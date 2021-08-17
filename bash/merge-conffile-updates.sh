#!/bin/bash
#
# Merge conffile updates after a Debian release update.
#
# Copyright (C) 2021  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later


# DESCRIPTION and WARNINGS
# ========================
#
# This script works similar to rpmconf(8).
#
# When you install (release) updates and configuration files change,
# you might get prompted to choose between keeping your local
# configuration or installing the default configuration from upstream
# instead.  (Third option: start a shell and do whatever you like.)
#
# The conflicted files will be named something like '*.dpkg-dist',
# '*.dpkg-removed' or '*.ucf-new'.
#
# This script is intended to find and identify these configuration
# file conflics and automatically call a tool or editor that helps you
# merge the old and new configuration.
#
# You can handle conflicts in various ways:
#
# 1) On every conflict, choosing to spawn a shell and then run this
#    script.  This is the safest way as every configuration is updated
#    before restarting a service.  But you also have to babysit the
#    upgrade process and handle every conflict manually.
#
#    Another benefit of this method is that the service gets restarted
#    automatically.
#
# 2) Choose to resolve all conflicts by always choosing to install the
#    new upstream version.  When all updates have been processed, you
#    can then run this script and merge all conflicts in a single
#    session.  This might lead to PROBLEMS when an important service
#    gets restarted with a default configuration before you get to
#    merge its configuration and restart it.
#
#    To circumvent the babysitting during the package installs, you
#    could add '-o Dpkg::Options::=--force-confnew' to your apt(8) to
#    always choose to install the new upstream version automatically.
#    (This might be tuned further by adding --force-confdef to prevent
#     some of the PROBLEMS stated above.)
#
#    Please note that after all merges have been done you have to
#    restart affected services manually (or just boot once after
#    everything is merged).
#
# 3) Choose to resolve all conflicts by always choosing to keep your
#    local configuration.  This is nearly the same as option 2) above:
#
#    You might get PROBLEMS with important services not starting
#    because of an outdated configuration file format.
#
#    The apt parameter becomes '-o Dpkg::Options::=--force-confold'.
#
#    Service restarts will be needed as well.
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
# Be sure to edit /etc/etckeeper/update-ignore.d/01update-ignore
# instead of /etc/.gitignore or the relevant lines will be overwritten
# by etckeeper later!
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
# - add --frontend option like rpmconf(8) to support other merge tools
# - try being an apt-hook
#   - if it works, include a description in to the instructions
# - find a proper name for conffiles like *.dpkg-* and *.ucf-*
#   - rename $conffile to that new name
#   - rename $basefile to $conffile
# - recreate the directory structore for intermediate files?
# - support three-way-merges?
#   is there a way to get the pristine conffile from the previous release?
# - set -e
# - rewrite in a proper language


#--------------------------------------------------------------------------------
# SUBS

set_sizes()
{
    local want_cols=$1 want_rows=$2

    cols=$(( $(tput cols  2>&1 || echo 60) - 4 ))
    rows=$(( $(tput lines 2>&1 || echo 18) - 2 ))

    if [ "$want_cols" -lt $cols ]; then
	cols=$want_cols
    fi

    if [ "$want_rows" -lt $rows ]; then
	rows=$want_rows
    fi
}

get_widest()
{
    local string
    local widest=0
    for string in "$@"; do
	if [ ${#string} -gt $widest ]; then
	    widest=${#string}
	fi
    done

    echo "$widest"
}

show_message()
{
    local title=$1 message=$2

    local widest
    widest=$( get_widest "$title" "$message" )

    set_sizes $(( widest + 10 )) 8

    whiptail --title "$title" --msgbox "$message" "$rows" "$cols"
}

select_from_entries()
{
    local title=$1 message=$2

    local widest
    widest=$( get_widest "$title" "$message" "${entries[@]}" )

    local overhead=8

    set_sizes $(( widest + 10 )) $(( ${#entries[@]} / 2 + overhead ))

    selection=$( whiptail --title "$title" --menu "$message" "$rows" "$cols" $(( rows - overhead )) "${entries[@]}" 3>&2 2>&1 1>&3- )
    selection_rc=$?
}

action_completed()
{
    local file=$1 action=$2
    
    action_id=$(( action_id + 1 ))

    show_message "$file OK" "$file $action"
}

action_aborted()
{
    local file=$1 action=$2
    
    show_message "ABORT: $file" "$file $action"
}

is_deleted()
{
    local file=$1

    [[ $file =~ \.(dpkg|ucf)-removed$ ]]
}

is_new()
{
    local file=$1

    [[ $file =~ \.(dpkg|ucf)-dist$ ]]
}

is_old()
{
    local file=$1

    [[ $file =~ \.(dpkg|ucf)-old$ ]]
}

temp_filename()
{
    local source=${1##*/}
    local action=${2:-unknown}

    printf '%s/%04d.%s..%s' "$tempdir" "$action_id" "$source" "$action"
}

clean_tempfiles()
{
    rmdir "$tempdir" 2>/dev/null || echo "echo intermediate files in $tempdir are kept"
}

init_tempfiles()
{
    action_id=0
    tempdir=$( mktemp --directory --tmpdir merge-conffile-updates.XXXXXXXXXX )

    trap clean_tempfiles EXIT
}

record_path()
{
    local file=$1

    echo "$file" > "$( temp_filename "$file" path )"
}

two_way_merge()
{
    local input1="$1" input2="$2" output="$3"

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
    action_completed "$conffile" "has been added and renamed to $basefile"
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

    local oldfile newfile
    if is_old "$conffile"; then
	oldfile=$conffile
	newfile=$basefile

    elif is_new "$conffile"; then
	oldfile=$basefile
	newfile=$conffile

    else
	action_aborted "$conffile" "trying to merge, but file with unknown extension .${conffile##*.} encountered, don't know what to do"
	return

    fi

    local input1 input2 output
    input1="$( temp_filename "$oldfile"  input.old  )"
    input2="$( temp_filename "$newfile"  input.new  )"
    output="$( temp_filename "$basefile" output     )"

    cp "$oldfile" "$input1"
    cp "$newfile" "$input2"
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

	entries=()
	entries+=('L' 'ist file')
	entries+=('R' 'remove file')
	entries+=('C' 'ancel')

	select_from_entries "$conffile" 'No current file found, this looks like a removal:'

	if [ $selection_rc -ne 0 ] || [ "$selection" = C ]; then
	    action_aborted "$conffile" 'not removed'
	    continue=no
    
	elif [ "$selection" = R ]; then
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

	entries=()
	entries+=('L' 'ist file')
	entries+=('A' 'add file')
	entries+=('C' 'ancel')

	select_from_entries "$conffile" 'No current file found, this looks like an addition:'

	if [ $selection_rc -ne 0 ] || [ "$selection" = C ]; then
	    action_aborted "$conffile" 'not added'
	    continue=no

	elif [ "$selection" = R ]; then
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

    action_aborted "$conffile" "single file with unknown extension .${conffile##*.} encountered, don't know what to do"
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
    entries=()
    local conffile
    # todo: unique tags: letters [a..z ,aa..zz , ...] or filenames
    tag=0
    for conffile in "${conffiles[@]}"; do
	entries+=("$tag" "$conffile")
	tag=$(( tag + 1 ))
    done

    select_from_entries 'merge conffiles' 'Select conffile to process:'

    if [ $selection_rc -ne 0 ]; then
	echo "$selection" >&2
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

	if [ $action_id -gt 0 ]; then
	    show_message 'nothing to do' 'no conffiles need merges'
	fi

	echo "no conffiles need merges"
	echo "finished"
	exit 0
    fi

    select_conffile

    handle_conffile "${conffiles[$selection]}"

done
