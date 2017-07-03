#!/bin/bash
#
# show valid days left on SSL certificate

# one-liner for multiple files:
# NOW=$(date +%s); for CERT in *.pem; do ENDDATE=$(date --date "$(openssl x509 -enddate -noout -in $CERT | cut -f 2 -d =)" +%s); printf "%6d days - %s\n" $(( ( $ENDDATE - $NOW ) / ( 60 * 60 * 24 ) )) "$CERT"; done | sort -n

# readable script for single file ($1):
CERT="$1"

NOW=$(date +%s)
END=$(date --date "$(openssl x509 -enddate -noout -in "$CERT" | cut -f 2 -d =)" +%s)

SECONDS_LEFT=$(( $END - $NOW ))
DAYS_LEFT=$(( $SECONDS_LEFT / ( 60 * 60 * 24 ) ))

printf "%6d days - %s\n" $DAYS_LEFT "$CERT"
