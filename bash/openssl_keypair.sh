#!/bin/bash

# 2007,2013,2014 (c) by Christian Garbs <mitch@cgarbs.de>

# Generate a one time CA and some signed keys
# OpenSSL keyhandling is a hassle o_O

set +e

VALID_DAYS=3650   # 10 years

## baut eine CA und signiert sie mit sich selbst
buildca()
{
    set +e

    openssl req -new -x509 -nodes -keyout $1.key -out $1.crt -days ${VALID_DAYS} -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
temporary CA for SSL keypair
root
.
.
EOF

    chmod 0600 $1.key $1.crt
    openssl x509 -in $1.crt -noout -next_serial -out serial

    touch index.txt

}


## baut einen Key und signiert ihn mit der CA
buildkey()
{
    set +e
    
    # -extensions server/client??
    # generate private key + certificate signing request
    openssl req -days ${VALID_DAYS} -nodes -new -keyout $1.key -out $1.csr -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
OpenSSL key $1
root
.
.
EOF

    # -extensions server/client??
    # sign request by CA
    openssl ca -days ${VALID_DAYS} -out $1.crt -in $1.csr -config openssl.cnf 2>/dev/null <<EOF
y
y
EOF

    chmod 0600 $1.key $1.crt $1.csr

}

## baut Sammeldateien aus CA, private und public key
buildpem()
{

    # öffentlicher Teil
    sed -n -e '/-----BEGIN/{:l1 p; n; b l1}' $1.crt >  $1-public.pem
    sed -n -e '/-----BEGIN/{:l1 p; n; b l1}' ca.crt >> $1-public.pem
    chmod 600 $1-public.pem

    # privater Teil
    cat $1.key $1-public.pem > $1-private.pem
    chmod 600 $1-private.pem

    # DH-Parameter anhängen
    openssl dhparam 2048 >> $1-private.pem

}
    

##### Verzeichnisse anlegen

TMPDIR=$(mktemp -d ./ssl.XXXXXXXX )
cd $TMPDIR

##### OpenSSL.cnf vorbereiten

< /etc/ssl/openssl.cnf \
sed \
-e 's/default_bits.*=.*$/default_bits = 4096/' \
-e 's/private_key.*=.*$/private_key = ca.key/' \
-e 's/certificate.*=.*/certificate = ca.crt/' \
-e 's/new_certs_dir.*=.*/new_certs_dir = ./' \
-e 's/database.*=.*/database = index.txt/' \
-e 's/serial.*=.*/serial = serial/' \
> openssl.cnf

##### eigene CA bauen

echo creating CA...

buildca ca

echo CA created

##### Keys bauen

echo building keys

buildkey one
buildkey two

echo keys built

##### PEMs generieren

echo building pems

buildpem one
buildpem two

echo pems built

##### cleanup

echo cleaning up
rm two.* one.* index.* ca.* serial* ????????????????????????????????????????.pem openssl.cnf

echo up cleant #sic! :-)

##### aufräumen

echo results are in $TMPDIR
# this really works!
# server:
#   $ stunnel -p ssl.*/one-private.pem -a ssl.* -A ssl.*/two-private.pem -f -d 8000 -r 80 -P /tmp/one.pid -v 3
# client:
#   $ stunnel -p ssl.*/two-private.pem -a ssl.* -A ssl.*/one-public.pem -f -r 8000 -c -P /tmp/two.pid -v 3

