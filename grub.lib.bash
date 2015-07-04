#!/bin/bash

function __GrubSetEtcDefaultVar() {
	echo "sed -Ei 's/^($1)=\"(.+)\"\$/\1=\"$2\"/' '$3'"
}

function __GrubHasEtcDefaultVar() {
	echo "grep -Eq '^($1)=\"(.+)\"\$' '$2'"
}

function GrubSetEtcDefaultVar() {
	local var="$(UtilToUpper "$1")" val="$2"
  local file="/etc/default/grub" empty="$4"

  [[ -n "${empty}" ]] || empty="${val}"

  Script "GrubAppendEtcDefaultVar" <<-EOF
	if $(__GrubHasEtcDefaultVar "${var}" "${file}"); then
	  $(__GrubSetEtcDefaultVar "${var}" "${val}" "${file}")
	else
	  echo '${var}="${empty}"' >> "${file}"
	fi
	EOF
}

function GrubAppendEtcDefaultVar() {
  GrubSetEtcDefaultVar "$1" "\2 $2" "$3" "$2"
}
