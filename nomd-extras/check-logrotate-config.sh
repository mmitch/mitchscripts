#!/bin/bash

OK() {
    echo "I:logrotate_config:$*"
}

FAIL() {
    echo "I:logrotate_config:$*"
}

config_is_set()
{
    local what=$1 where=$2
    grep -q -P "^\\s*$what\b" "$where"
}

config_must_be_set()
{
    local what=$1 where=$2
    
    if config_is_set "$what" "$where"; then
	OK "option '$what' is set in $where"
    else
	FAIL "option '$what' is not set in $where"
    fi
}

config_must_not_be_set()
{
    local what=$1 where=$2

    if ! config_is_set "$what" "$where"; then
	OK "option '$what' is not set in $where"
    else
	FAIL "option '$what' is set in $where"
    fi
}

# dateext should always be enabled
config_must_be_set dateext /etc/logrotate.conf

# compress should be disabled only when we use ZFS
if [ "$(stat -f -c %T /var/log)" = zfs ] ; then

    {
	echo /etc/logrotate.conf
	find /etc/logrotate.d -type f
    } | while read -r config; do
	config_must_not_be_set compress "$config"
    done
fi
