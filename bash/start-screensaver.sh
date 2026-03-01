#!/bin/sh
xset +dpms s blank s 240
# -secure disabled remote-Steuerung! (mplayer, dwm-mitch etc.)
/usr/bin/xautolock -time 4 -locker ~/bin/slock -notify 30 -notifier "notify-send -u critical -t 10000 -i important -- 'LOCKING SCREEN' 'in 30 seconds'"

