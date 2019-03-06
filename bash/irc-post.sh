#!/bin/bash
#
# send STDIN to USER via IRC without joining a channel
#
# Copyright (C) 2019  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v3 or later
#

IRCSERVER="$1"
IRCPORT="$2"
NICK="$3"
TARGET="$4"

if [ -z "$IRCSERVER" ] || [ -z "$IRCPORT" ] || [ -z "$NICK" ] || [ -z "$TARGET" ] \
       || [ "$IRCSERVER" = "-h" ] || [ "$IRCSERVER" = "--help" ]; then
    echo "usage:  irc-post.sh <IRCSERVER> <IRCPORT> <NICKNAME> <TARGET>"
    exit
fi

set -e

exec >/dev/tcp/$IRCSERVER/$IRCPORT # todo: multi-server-fallback
echo "USER $NICK 8 * : $NICK bot"
echo "NICK $NICK"
sleep 1
while read -r LINE; do
    echo "PRIVMSG $TARGET :$LINE"
    sleep 0.5
done
echo "QUIT"
