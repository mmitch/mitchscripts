#!/bin/bash
#
# show valid days left on SSL certificate
#
# usage:
#   openssl_cert_valid_days.sh [ -max days ] cert-pem [ cert-pem [...] ]

set -e

NOW=$(date +%s)

MAX_DAYS=0

if [ "$1" eq '-max' ]; then
    MAX_DAYS=$2
    shift 2
fi

for CERT in "$@"; do
    
    END=$(date --date "$(openssl x509 -enddate -noout -in "$CERT" | cut -f 2 -d =)" +%s)
    
    SECONDS_LEFT=$(( $END - $NOW ))
    DAYS_LEFT=$(( $SECONDS_LEFT / ( 60 * 60 * 24 ) ))

    if [ $MAX_DAYS -gt 0 -a $DAYS_LEFT -gt $MAX_DAYS ]; then
	next
    fi
    
    printf "%6d days - %s\n" $DAYS_LEFT "$CERT"
    
done
