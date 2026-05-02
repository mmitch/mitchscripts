#!/bin/bash

log() {
    printf "%(%Y-%m-%d %H:%M:%S)Th %s\n" -1 "$*"
    echo "dpms watch: $*" | ~/git/mitchscripts/bash/irc-post.sh localhost 6667 nomd \#chatops
}

log_maybe() {
    [ "$quiet_for_cron" = yes ] || log "$@"
}

on_exit() {
    rm -f "$PIDFILE"
    log "EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

is_screen_saved_but_not_off() {
    pidof slock >/dev/null && { xset q | grep -q 'Monitor is On'; }
}

PIDFILE=/var/run/user/$UID/keep-screensaver-saved.pid

prevent_duplicate_run() {
    if [ -e "$PIDFILE" ]; then
	read -r pid < "$PIDFILE"
	local PID_FOUND="found PIDFILE in $PIDFILE with PID $pid"
	if [ -d /proc/$pid ]; then
	    log_maybe "$PID_FOUND"
	    log_maybe "ERROR: pid still exists, won't start!"
	    exit 1
	else
	    log "$PID_FOUND"
	    log 'PID does not exist any more, starting anyways, capturing PIDFILE'
	fi
    fi

    echo $$ > "$PIDFILE"
}

check_x11_connectivity() {
    if ! pidof dwm; then
	log_maybe "no dwm found, not starting"
	exit 1
    fi

    export DISPLAY=:0

    if ! xhost >/dev/null 2>&1; then
	log_maybe "DISPLAY=$DISPLAY seems invalid, not starting"
	exit 1
    fi
}

start_screensaver_if_missing() {
    if ! pidof -q xautolock; then
	log 'xautolock is gone! checking for X11 connectivity'
	check_x11_connectivity

	log 'xautolock is gone! trying to restart'
	( nohup ~/bin/start-screensaver.sh & ) &
    fi
}

##################################################

if [ "$1" = -quiet ]; then
    quiet_for_cron=yes
fi

check_x11_connectivity
prevent_duplicate_run
trap on_exit EXIT

start_screensaver_if_missing

log 'started'

while sleep 59; do

    if [ "$(printf '%(%H%M)T' -1)" = "0000" ]; then
	log 'still alive'
    fi

    if is_screen_saved_but_not_off; then
	# perhaps we are currently disabling the screensaver, give us some seconds of slack
	sleep 10
	if is_screen_saved_but_not_off; then
	    # status unchanged, turn the screen off
	    xset dpms force off
	fi
    fi

    start_screensaver_if_missing
done
