#!/bin/bash

#
# Setup Functions
#

function __NetTCPPortOpen() {
	if [[ $# -eq 2 ]]; then
		host=$1 port=$2
	elif [[ $# -eq 1 ]]; then
		host="127.0.0.1" port="$1"
	else
		return 1
	fi

	timeout 1 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" &>/dev/null
}
