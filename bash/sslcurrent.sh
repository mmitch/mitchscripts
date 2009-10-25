#!/bin/sh
# display current song on Sunshine Live
lynx --reload --dump --width=500 http://www.sunshine-live.de/onair/ \
|grep -A 10 'Zeit.*Titel.*Interpret' \
| egrep '[0-9]+:[0-9]+.Uhr' \
| tail -n 1 \
| sed 's/^\s*[0-9]*:[0-9]*.Uhr.//'
