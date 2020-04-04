#!/bin/bash

exec 1< /dev/null
exec 1> /tmp/xsession-stdout
exec 2> /tmp/xsession-stderr

[ "$BASH_VERSION" ] && . /home/mitch/git/mitchscripts/config/setup-PATH

[ -r ~/.Xresources ] && xrdb ~/.Xresources

# use old font rendering, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=866685
export FREETYPE_PROPERTIES=truetype:interpreter-version=35

#export DMENU_COLORS="-fn fixed -nb #336 -nf #ccc -sb #669 -sf #eee"
export DMENU_COLORS="-fn fixed -nb #222 -nf #ddd -se #222"

( sleep 2; cd Dropbox/backgrounds/ && ./feh-random-bg ) &
# ( floatbg -satmid 0.2 -satvar 0.15 -fase 0.1 -value 0.3 & ) &
# feh --no-fehbg --bg-center ~/iss2.png ~/iss1.png

# hide the mouse - unclutter has some issues
xbanish &

# fix Java GUI breakages (see dwm website)
# export AWT_TOOLKIT=MToolkit # <- this breaks Eclipse 2019-12
# [ -x /usr/bin/wmname ] && /usr/bin/wmname LG3D

# ask SSH password
~/bin/ssh-addkeys < /dev/null

# start notification if networked
(ssh -X mitch "/home/mitch/git/mitchscripts/bash/start_notification.sh &" &) &

# Thinkpad blaue links-/rechts-Tasten im Cursorblock
#xmodmap -e 'keycode 233 = F33'
#xmodmap -e 'keycode 234 = F34'

# http://stereopsis.com/flux/
## ~/xflux -l 51.151786 -g 10.415039 -k 4500 # 36 is cool  2700 (3400) 4200
[ -x /usr/bin/redshift ] && /usr/bin/redshift -l 51.151786:10.415039 &

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

# KEYBOARD NORMALISIEREN!!! AccessX ausmachen
xkbset -a

# ein Terminal starten
# ( sleep 2; x-terminal-emulator ) &

# Screensaver
# -secure disabled remote-Steuerung! (mplayer, dwm-mitch etc.)
[ -x /home/mitch/bin/slock ] && [ -x /usr/bin/xautolock ] && ( xset +dpms s blank s 240; /usr/bin/xautolock -time 4 -locker /home/mitch/bin/slock -notify 30 -notifier "notify-send -u critical -t 10000 -i important -- 'LOCKING SCREEN' 'in 30 seconds'" ) &

# Notifications
[ -x dunst ] && dunst &

# emacs vorstarten
emacs --daemon &
