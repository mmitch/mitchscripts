#!/bin/bash
# $Id: openvpn_conf.sh,v 1.10 2007-05-13 10:24:01 mitch Exp $

# 2007 (c) by Christian Garbs <mitch@cgarbs.de>

# Generate a one time CA, server and client keys
# OpenSSL keyhandling is a hassle o_O

set +e

## baut eine CA und signiert sie mit sich selbst
sub buildca()
{
    set +e

    openssl req -new -x509 -nodes -keyout $1.key -out $1.crt -days 3650 -config openssl.cnf 2>/dev/null <<EOF
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
sub buildkey()
{
    set +e
    
    # -extensions server/client??
    # generate private key + certificate signing request
    openssl req -days 3650 -nodes -new -keyout $1.key -out $1.csr -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
server OpenSSL key
root
.
.
EOF

    # -extensions server/client??
    # sign request by CA
    openssl ca -days 3650 -out $1.crt -in $1.csr -config openssl.cnf 2>/dev/null <<EOF
y
y
EOF

    chmod 0600 $1.key $1.crt $1.csr

}

## baut Sammeldateien aus CA, private und public key
sub buildpem()
{

    # öffentlicher Teil
    sed -n -e '/-----BEGIN/{:l1 p; n; b l1}' $1.crt >  $1-public.pem
    sed -n -e '/-----BEGIN/{:l1 p; n; b l1}' ca.crt >> $1-public.pem

    # privater Teil
    cat $1.key $1-public.pem > $1-private.pem

}
    

##### Verzeichnisse anlegen

TMPDIR=$(mktemp -d ./ssl.XXXXXXXX )
cd $TMPDIR

##### OpenSSL.cnf vorbereiten

< /etc/ssl/openssl.cnf \
sed \
-e 's/default_bits.*=.*$/default_bits = 2048/' \
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

##### DH bauen

echo creating DH...

openssl dhparam -out dh1024.pem 1024
chmod 600 dh1024.pem

echo DH created

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

##### aufräumen

echo results are in $TMPDIR
echo copy server.pem + client-ca.pem to server
echo copy client.pem + server-ca.pem to client
echo run c_rehash on both systems
