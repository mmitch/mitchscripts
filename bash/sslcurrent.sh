#!/bin/sh
# display current song on Sunshine Live
GET http://www.sunshine-live.de/ \
| grep '<!-- $now -->' \
| sed -e 's/^.*"teasertext">//' -e 's:<br />:\n:g' -e 's:</p>:\n:' \
| head -n 3 \
| tail -n 2
