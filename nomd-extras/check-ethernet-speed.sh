#!/bin/bash

OK() {
    echo "I:ethernet_speed:$*"
}

FAIL() {
    echo "C:ethernet_speed:$*"
}

device=${1:-eth0}
expected_speed=${2:-1000Mb/s}

actual_speed=$(LANG=C /sbin/ethtool "$device" 2>&1 | awk '/Speed:/ { print $2 }')

if [ "$actual_speed" = "$expected_speed" ]; then
    OK "$device has $actual_speed"
else
    FAIL "$device has $actual_speed instead of $expected_speed"
fi
