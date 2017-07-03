#!/bin/bash
#
# show valid days left on SSL certificate
#
# usage:
#   openssl_cert_valid_days.sh cert-pem [ cert-pem [...] ]

NOW=$(date +%s)

for CERT in "$@"; do
    
    END=$(date --date "$(openssl x509 -enddate -noout -in "$CERT" | cut -f 2 -d =)" +%s)
    
    SECONDS_LEFT=$(( $END - $NOW ))
    DAYS_LEFT=$(( $SECONDS_LEFT / ( 60 * 60 * 24 ) ))
    
    printf "%6d days - %s\n" $DAYS_LEFT "$CERT"
    
done
