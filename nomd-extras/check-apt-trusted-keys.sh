#!/bin/bash

OK() {
    echo "I:apt_trusted_keys:$*"
}

FAIL() {
    echo "C:apt_trusted_keys:$*"
}

for file in /etc/apt/trusted.gpg.d/*; do
    if [[ $(basename "$file") =~ ^debian-archive- ]]; then
	OK "looks like Debian original: $file"
    else
	FAIL "unexpected file: $file"
    fi
done
