#!/bin/bash

exec 1< /dev/null
exec 1> /tmp/xsession-stdout
exec 2> /tmp/xsession-stderr

[ -r ~/.Xresources ] && xrdb -merge ~/.Xresources

#export DMENU_COLORS="-fn fixed -nb #336 -nf #ccc -sb #669 -sf #eee"
export DMENU_COLORS="-fn fixed -nb black -nf white"

( floatbg -satmid 0.2 -satvar 0.15 -fase 0.1 -value 0.3 & ) &
# feh --bg-center ~/iss2.png ~/iss1.png

# this breaks mouse centering in WoW
# ( unclutter -idle 3 & ) &

export AWT_TOOLKIT=MToolkit

# ask SSH password
ssh-add < /dev/null

# start notification if networked
(ssh -X mitch@mitch.mitch.h.shuttle.de "/home/mitch/git/mitchscripts/bash/start_notification.sh &" &) &

#( synergys & ) &

# Thinkpad blaue links-/rechts-Tasten im Cursorblock
#xmodmap -e 'keycode 233 = F33'
#xmodmap -e 'keycode 234 = F34'

#~/perl/xtermcolorwrap.pl &

# http://stereopsis.com/flux/
## ~/xflux -l 51.151786 -g 10.415039 -k 4500 # 36 is cool  2700 (3400) 4200

# Mausrad verdrehen
~/git/mitchscripts/bash/reverse_scrollwheel.sh

# Numlock an!
numlockx on

# PARTY!
#(
#    mount /mnt/video
#    VIDEOFILE="$(find /mnt/video/youtube/ -type f | shuffle | head -1)"
#    ln -sf "$VIDEOFILE" /tmp/last_login_video
#    mplayer -really-quiet "$VIDEOFILE" &
#) &


# Dropbox
#LANG=C LC_MESSAGE=C LANGUAGE=C /home/mitch/.dropbox-dist/dropboxd &
#encfs -S /home/mitch/Dropbox/.CRYPT/ /home/mitch/Cryptbox < /home/mitch/.encfspassword &

# KEYBOARD NORMALISIEREN!!! AccessX ausmachen
xkbset -a

# ein Terminal starten
# ( sleep 2; x-terminal-emulator ) &