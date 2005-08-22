#!/bin/bash
# $Id: openvpn_conf.sh,v 1.5 2005-08-22 21:48:42 mitch Exp $

# 2005 (c) by Christian Garbs <mitch@cgarbs.de>

# Generate a one time CA + server and client keye + OpenVPN
# configuration.  This gets you everything you need to set up a
# point2point OpenVPN connection that connects two LANs to each other.
# OpenSSL keyhandling is a hassle o_O

set +e

TMPDIR=$(mktemp -d)

##### Parameter abfragen

echo "port? [e.g. 1195]"
read PORT
echo "server hostname? [e.g. nukunuku.yamamaya.is-a-geek.net]"
read HOST_SRV
echo "server ip? [e.g. 192.168.8.1]"
read IP_SRV
echo "server network? [e.g. 192.168.0.0]"
read NET_SRV
echo "server netmask? [e.g. 255.255.255.0]"
read MASK_SRV
echo "server tun? [e.g. tun2]"
read TUN_SRV
echo "client hostname?"
read HOST_CLT
echo "client ip?"
read IP_CLT
echo "client network? [e.g. 192.168.0.0]"
read NET_CLT
echo "client netmask? [e.g. 255.255.255.0]"
read MASK_CLT
echo "client tun?"
read TUN_CLT

echo
echo
echo

##### Verzeichnisse anlegen

COMBINED=${HOST_SRV}_${HOST_CLT}
CONFDIR_SRV=$HOST_SRV/etc/openvpn/$COMBINED
CONFDIR_CLT=$HOST_CLT/etc/openvpn/$COMBINED
CONF_SRV=${CONFDIR_SRV}_server.conf
CONF_CLT=${CONFDIR_CLT}_client.conf

mkdir -p $CONFDIR_SRV $CONFDIR_CLT

##### OpenSSL.cnf vorbereiten

< /etc/ssl/openssl.cnf \
sed \
-e 's/default_bits.*=.*$/default_bits = 2048/' \
-e 's/private_key.*=.*$/private_key = ca.key/' \
-e 's/certificate.*=.*/certificate = ca.crt/' \
-e 's/new_certs_dir.*=.*/new_certs_dir = ./' \
-e 's/database.*=.*/database = index.txt/' \
-e 's/serial.*=.*/serial = serial/' \
> $TMPDIR/openssl.cnf

##### eigene CA bauen

CA_PASSWORD='fest_weil_sowieso_wieder_geloescht'

echo creating CA...

(
    set +e

    cd $TMPDIR

    openssl req -new -x509 -nodes -keyout ca.key -out ca.crt -days $DAYS 3650 -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
temporary CA for VPN P2P tunnel
root@$(hostname -f)
.
.
EOF

    chmod 0600 ca.key ca.crt
    openssl x509 -in ca.crt -noout -next_serial -out serial

    touch index.txt

)

cp $TMPDIR/ca.crt $CONFDIR_SRV
cp $TMPDIR/ca.crt $CONFDIR_CLT

echo CA created

##### DH bauen

echo creating DH...

openssl dhparam -out $CONFDIR_SRV/dh1024.pem 1024
chmod 600 $CONFDIR_SRV/dh1024.pem

echo DH created

##### Server-Key bauen

echo building server key

(
    set +e
    
    cd $TMPDIR

    # -extensions server 
    openssl req -days 3650 -nodes -new -keyout $HOST_SRV.key -out $HOST_SRV.csr -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
$HOST_SRV OpenVPN SSL Key
root@$HOST_SRV
.
.
EOF

    # -extensions server
    openssl ca -days 3650 -out $HOST_SRV.crt -in $HOST_SRV.csr -config openssl.cnf 2>/dev/null <<EOF
y
y
EOF
    chmod 0600 $HOST_SRV.key
    chmod 0600 $HOST_SRV.crt
    chmod 0600 $HOST_SRV.csr
)

cp $TMPDIR/$HOST_SRV.key $CONFDIR_SRV
cp $TMPDIR/$HOST_SRV.crt $CONFDIR_SRV

echo server key built

##### Client-Key bauen

echo building client key

(
    set +e
    
    cd $TMPDIR

    # -extensions client 
    openssl req -days 3650 -nodes -new -keyout $HOST_CLT.key -out $HOST_CLT.csr -config openssl.cnf 2>/dev/null <<EOF
DE
n/a
.
private
.
$HOST_CLT OpenVPN SSL Key
root@$HOST_CLT
.
.
EOF

    # -extensions client
    openssl ca -days 3650 -out $HOST_CLT.crt -in $HOST_CLT.csr -config openssl.cnf 2>/dev/null <<EOF
y
y
EOF
    chmod 0600 $HOST_CLT.key
    chmod 0600 $HOST_CLT.crt
    chmod 0600 $HOST_CLT.csr
)

cp $TMPDIR/$HOST_CLT.key $CONFDIR_CLT
cp $TMPDIR/$HOST_CLT.crt $CONFDIR_CLT

echo client key built

##### Server-Config bauen

echo building server configuration

cat > $CONF_SRV <<EOF
#tun-ipv6
ca      $COMBINED/ca.crt
cert    $COMBINED/$HOST_SRV.crt
key     $COMBINED/$HOST_SRV.key
dh      $COMBINED/dh1024.pem
dev $TUN_SRV
float
ifconfig $IP_SRV $IP_CLT
key-method 2
persist-key
persist-tun
ping 15
ping-restart 300
ping-timer-rem
port $PORT
push "route $NET_SRV $MASK_SRV" 
remote $HOST_CLT
resolv-retry infinite
route $NET_CLT $MASK_CLT
tls-server
tun-mtu 1427
verb 3
EOF

echo server configuration built

##### Client-Config bauen

echo building client configuration

cat > $CONF_CLT <<EOF
#tun-ipv6
ca      $COMBINED/ca.crt
cert    $COMBINED/$HOST_CLT.crt
key     $COMBINED/$HOST_CLT.key
dev $TUN_CLT
ifconfig $IP_CLT $IP_SRV
key-method 2
persist-key
persist-tun
ping 15
ping-restart 300
ping-timer-rem
port $PORT
remote $HOST_SRV
route $NET_SRV $MASK_SRV
tls-client
tun-mtu 1427
verb 3
EOF

echo client configuration built

##### aufräumen

rm -r $TMPDIR
