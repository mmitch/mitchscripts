#!/bin/bash
#
# send STDIN to USER via IRC without joining a channel
#
# Copyright (C) 2019, 2021, 2024  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#

IRCSERVER="$1"
IRCPORT="$2"
NICK="$3"
TARGET="$4"

if [ -z "$IRCSERVER" ] || [ -z "$IRCPORT" ] || [ -z "$NICK" ] || [ -z "$TARGET" ] \
       || [ "$IRCSERVER" = "-h" ] || [ "$IRCSERVER" = "--help" ]; then
    cat <<EOF
usage:  irc-post.sh <IRCSERVER> <IRCPORT> <NICKNAME> <TARGET>

<TARGET> can either be a nick or a #channel
EOF
    exit
fi

set -e

connected=no

exec >/dev/tcp/"$IRCSERVER"/"$IRCPORT" # todo: multi-server-fallback
while read -r LINE; do
    if [ "$connected" = no ]; then
	echo "USER $NICK 8 * :$NICK bot"
	echo "NICK $NICK"
	sleep 1
	connected=yes
    fi
    echo "PRIVMSG $TARGET :$LINE"
    sleep 0.5
done
if [ "$connected" = yes ]; then
    echo "QUIT"
fi
