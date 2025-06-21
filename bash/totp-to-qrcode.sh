#!/bin/bash
#
# Take an TOTP key (eg. from oathtool's /etc/users.oath) and
# convert to a QR Code ready for import into eg. Google Authenticator.
#
# Keep the generated QR Code private in all cases!
#
# Copyright (C) 2025  Christian Garbs <mitch@cgarbs.de>
# licensed under GNU AGPL v3 or later

# for format decription, see
# https://github.com/google/google-authenticator/wiki/Key-Uri-Format

# FIXME: add format selection parameters instead of relying on auto-detection

# FIXME: issuer should be optional and account a must-have, but Google Authenticator won't import without an issuer

# FIXME: only TOTP so far, no HOTP
type=totp

die() {
    echo "$@" >&2
    exit 1
}

show_help() {
    cat <<EOF
usage:
  $0 -h
  $0 --help
  $0 ISSUER [ ACCOUNTNAME }

The KEY will be read from STDIN (1st line only).
EOF
}

## handle help

if [ "$1" = -h ] || [ "$1" = --help ]; then
    show_help
    exit 0
fi

## parse and validate ISSUER and ACCOUNTNAME arguments

issuer=$1
shift

if [ -z "$issuer" ]; then
    die "no ISSUER given"
fi

if [ "$1" ]; then
    account=$1
    shift
else
    account=
fi


if [ "$*" ]; then
    die "additional arguments given"
fi

## parse key

read -r key_any

if [[ $key_any =~ ^[0-9a-fA-F]+$ ]]; then
    echo "key autodetection: hex format"
    key_hexed=$(sed -E 's/([0-9a-fA-F]{2})/\\x\1/gI' <<<"$key_any")
    key_base32=$(printf "$key_hexed" | base32)
elif [[ $key_any =~ ^[a-zA-Z2-7=" "]+$ ]]; then
    echo "key autodetection: base32 format"
    key_base32=${key_any^^}
    key_base32=${key_base32// /}
else
    echo "key autodetection: plaintext"
    key_base32=$(base32 <<<"$key_any")
fi

## build URI

if [ $account ]; then
    printf -v uri 'otpauth://%s/%s:%s?secret=%s&issuer=%s' "$type" "$issuer" "$account" "${key_base32%%=*}" "$issuer"
else
    printf -v uri 'otpauth://%s/%s:?secret=%s&issuer=%s' "$type" "$issuer" "${key_base32%%=*}" "$issuer"
fi

## debug possibility

if true; then
    echo "key_any   = $key_any"
    echo "key_hexed = $key_hexed"
    echo "key_base32= $key_base32"
    echo "$uri"
fi

## display QR code

qrencode -t ansiutf8 <<<"$uri"
