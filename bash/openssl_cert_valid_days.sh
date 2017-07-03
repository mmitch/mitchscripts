#!/bin/bash
#
# show valid days left on SSL certificate

set -e

NOW=$(date +%s)

MAX_DAYS=0

while getopts 'hm:' opt; do
    case $opt in
	m)
	    MAX_DAYS=$OPTARG
	    ;;
	*)
	    echo "usage:"
	    echo "    openssl_cert_valid_days.sh [ -h ] [ -m days ] cert-pem [ cert-pem [...] ]"
	    echo "        -h        show help (and do nothing else)"
	    echo "        -m days   don't list certificates valid longer than given days"
	    exit 0
	    ;;
    esac
done
shift $((OPTIND-1))

for CERT in "$@"; do
    
    END=$(date --date "$(openssl x509 -enddate -noout -in "$CERT" | cut -f 2 -d =)" +%s)
    
    SECONDS_LEFT=$(( $END - $NOW ))
    DAYS_LEFT=$(( $SECONDS_LEFT / ( 60 * 60 * 24 ) ))

    if [ $MAX_DAYS -gt 0 -a $DAYS_LEFT -gt $MAX_DAYS ]; then
	continue
    fi
    
    printf "%6d days - %s\n" $DAYS_LEFT "$CERT"
    
done
