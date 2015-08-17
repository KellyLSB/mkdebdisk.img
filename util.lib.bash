#!/bin/bash

#
# Utility Functions
#

function UtilToUpper() {
	awk '{print toupper($0)}' <<<"$@"
}

function UtilToLower() {
	awk '{print tolower($0)}' <<<"$@"
}

function UtilConstantize() {
	UtilToUpper "$@" | sed 's/[^A-Z]+/_/g' | UtilToLower
}

function UtilDasherize() {
	UtilToUpper "$@" | sed 's/[^A-Z]+/-/g' | UtilToLower
}

function UtilCountLines() {
	wc -l <<<"$1"
}

function UtilBasenameNoExt() {
	echo -n "$(basename $1 | awk -F'.' '{ $NF=""; print $0 }'| xargs)"
}

#
# Build Functions
#

function AddFile() {
	File "AddFile" "$2" ${@:3} <<-EOF
	$(cat "$1")
	EOF
}
