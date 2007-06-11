#!/bin/bash
#
# $Id: update.sh,v 1.2 2007-06-11 21:36:16 mitch Exp $
#
# 2007 (c) by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL
#
# download www statistics from info.shuttle.de
#

# halt on error
set -e

# read user & password from text file (format: "user:passwd")
read USERPASSWD < ./.userpasswd 
[ -z "$USERPASSWD" ] && echo "user/password empty" && exit 1

# get last download
LATEST=
[ -e ./LATEST ] && read LATEST < ./LATEST

# set variables
USER=${USERPASSWD/:*}
DIR="https://${USERPASSWD}@info.shuttle.de/weblogs/${USER}/"

# prepare directories
mkdir -p ./download ./logs

# get list of all ZIPs and download new archives
echo "${DIR}" \
    | wget --no-check-certificate -q -O- -i- \
    | sed -e 's/^.*<a href="//' -e 's/">.*$//' \
    | grep .zip \
    | while read FILE; do
    if [ "${FILE}" \> "${LATEST}" ] ; then
	echo "${DIR}${FILE}"
	echo "${FILE}" > LATEST
    fi
done \
    | ( cd download ; wget --no-check-certificate -qi- )

# unzip archives
for ZIP in ./download/*.zip; do
    unzip -joq ${ZIP} -d logs && rm ${ZIP}    
done

# call webalizer
(
    for LOG in ./logs/*; do
	cat $LOG
    done
) \
    | webalizer
