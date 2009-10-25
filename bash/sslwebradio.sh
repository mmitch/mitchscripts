#!/bin/bash
# listen to Sunshine Live webradio without a browser
#
# needs libwww-perl and mplayer

# official starting point (switch to mp3?)
URL="http://edge.download.newmedia.nacamar.net/sltokens/stream-radio-player.php?stream=sunshinelive/livestream.wma"
TMP=$(mktemp) || exit 1
GET "$URL" > "$TMP"

# first redirection
FILENAME=" $(grep FileName "$TMP" | sed -e 's,^.*VALUE=\\",,' -e 's,\\".*,,' )"

MYADID=0
TOKEN="$(grep -e 'var *token *=' "$TMP" | sed -e 's/^.*var *token *= *"//' -e 's/".*//')"
STREAM="$(grep -e 'var *stream *=' "$TMP" | sed -e 's/^.*var *stream *= *"//' -e 's/".*//')"
CONTENTTYPE="$(grep -e 'var *contentType *=' "$TMP" | sed -e 's/^.*var *contentType *= *"//' -e 's/".*//')"

rm "$TMP"

URL="$(
echo $FILENAME | sed \
-e 's,"+myAdID+",'"$MYADID," \
-e 's,"+token+",'"$TOKEN," \
-e 's,"+stream+",'"$STREAM," \
-e 's,"+contentType+",'"$CONTENTTYPE,"
)"

# second redirection and player start
mplayer "$( GET "$URL" | grep HREF=\"mms | sed -e 's/^.*HREF="//' -e 's/".*//' )"

