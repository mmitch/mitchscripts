#!/bin/bash

log() {
    printf "%(%Y-%m-%d %H:%M:%S)Th %s\n" -1 "$*"
    echo "dpms watch: $*" | ~/git/mitchscripts/bash/irc-post.sh localhost 6667 nomd \#chatops
}

on_exit() {
    rm -f "$PIDFILE"
    log "EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
}

is_screen_saved_but_not_off() {
    pidof slock >/dev/null && { xset q | grep -q 'Monitor is On'; }
}

PIDFILE=/var/run/user/$UID/keep-screensaver-saved.pid

if [ -e "$PIDFILE" ]; then
    read -r pid < "$PIDFILE"
    log "found PIDFILE in $PIDFILE with PID $pid"
    if [ -d /proc/$pid ]; then
	log "ERROR: pid still exists, won't start!"
	exit 1
    else
	log 'PID does not exist any more, starting anyways, capturing PIDFILE'
    fi
fi

echo $$ > "$PIDFILE"

trap on_exit EXIT

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

    if ! pidof -q xautolock; then
	log 'xautolock is gone! trying to restart'
	( nohup ~/bin/start-screensaver.sh & ) &
    fi
done
