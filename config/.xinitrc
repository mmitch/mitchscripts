#!/bin/bash

exec 1< /dev/null
exec 1> /tmp/xsession-stdout
exec 2> /tmp/xsession-stderr

# run command only if it is present
# - binary names with a path are used as given and checked to exist and be executable
# - binaries without path are looked up in $PATH
ifpresent()
{
    local bin=$1
    shift
    if [[ "$bin" =~ / ]]; then
	[ -x "$bin" ] && "$bin" "${@}"
    else
	bin=$(command -v "$bin") && "$bin" "${@}"
    fi
}

[ "$BASH_VERSION" ] && [ -e ~/git/mitchscripts/config/setup-PATH ] && . ~/git/mitchscripts/config/setup-PATH

[ -r ~/.Xresources ] && xrdb ~/.Xresources

# use old font rendering, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=866685
export FREETYPE_PROPERTIES=truetype:interpreter-version=35

#export DMENU_COLORS="-fn fixed -nb #336 -nf #ccc -sb #669 -sf #eee"
#export DMENU_COLORS="-fn fixed -nb #222 -nf #ddd -se #222"
export DMENU_COLORS="-fn -*-terminus-medium-r-*-*-18-*-*-*-*-*-*-*,-*-*-*-*-*-*-17-*-*-*-*-*-jisx0208.1983-* -nb #222 -nf #ddd -se #222"

if [ -d Dropbox/backgrounds/ ]; then
    ( sleep 2; cd Dropbox/backgrounds/ && ./feh-random-bg ) &
else
    ifpresent floatbg -satmid 0.2 -satvar 0.15 -fase 0.1 -value 0.3 &
fi

# hide the mouse - unclutter has some issues
ifpresent xbanish &

# fix Java GUI breakages (see dwm website)
# export AWT_TOOLKIT=MToolkit # <- this breaks Eclipse 2019-12
# [ -x /usr/bin/wmname ] && /usr/bin/wmname LG3D

# fix further Java GUI breakage (from IntelliJ)
# export _JAVA_AWT_WM_NONREPARENTING=1

# no hiding scrollbars
export GTK_OVERLAY_SCROLLING=0

# ask SSH password
ifpresent ~/bin/ssh-addkeys < /dev/null

# start notification if networked
(ssh -X mitch "/home/mitch/git/mitchscripts/bash/start_notification.sh &" &) &

# Thinkpad blaue links-/rechts-Tasten im Cursorblock
#xmodmap -e 'keycode 233 = F33'
#xmodmap -e 'keycode 234 = F34'

# http://stereopsis.com/flux/
## ~/xflux -l 51.151786 -g 10.415039 -k 4500 # 36 is cool  2700 (3400) 4200
ifpresent redshift -l 51.151786:10.415039 &

# Mausrad verdrehen
ifpresent ~/git/mitchscripts/bash/reverse_scrollwheel.sh

# Numlock an!
ifpresent numlockx on

# PARTY!
#(
#    mount /mnt/video
#    VIDEOFILE="$(find /mnt/video/youtube/ -type f | shuffle | head -1)"
#    ln -sf "$VIDEOFILE" /tmp/last_login_video
#    mplayer -really-quiet "$VIDEOFILE" &
#) &


# Dropbox
#LANG=C LC_MESSAGE=C LANGUAGE=C ~/.dropbox-dist/dropboxd &

# KEYBOARD NORMALISIEREN!!! AccessX ausmachen
ifpresent xkbset -a

# ein Terminal starten
# ( sleep 2; x-terminal-emulator ) &

# Screensaver
# -secure disabled remote-Steuerung! (mplayer, dwm-mitch etc.)
[ -x ~/bin/slock ] && [ -x /usr/bin/xautolock ] && ( xset +dpms s blank s 240; /usr/bin/xautolock -time 4 -locker ~/bin/slock -notify 30 -notifier "notify-send -u critical -t 10000 -i important -- 'LOCKING SCREEN' 'in 30 seconds'" ) &

# emacs vorstarten
ifpresent emacs --daemon &

# Meldungen von Handy und Tablet
ifpresent kdeconnect-indicator &

# mal schauen, das geht bei jedem Restart kaputt
ifpresent systemctl --user restart xdg-desktop-portal-gtk.service &

# Fan nach booten leiser
ifpresent fan 80 &

# auf Bildschirmschoner aufpassen
ifpresent bin/keep-screensaver-saved.sh &

# Stereo-Verteilung initialisieren
ifpresent bin/volume-down &
